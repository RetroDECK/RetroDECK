#!/bin/bash

DRY_RUN=0
LOCAL=0
LOCAL_PATH=""
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    --local)
      LOCAL=1
      ;;
    --local=*)
      LOCAL=1
      LOCAL_PATH="${arg#--local=}"
      ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--local[=PATH]]"
      echo "  --dry-run       Run locally but do not commit/push or auth to GitHub."
      echo "  --local[=PATH]  Use an existing local flathub repository (default: current dir); do not clone from GitHub."
      exit 0
      ;;
  esac
done

# default local path to current dir when --local provided without path
if [ "$LOCAL" -eq 1 ] && [ -z "$LOCAL_PATH" ]; then
  LOCAL_PATH="$PWD"
fi

# Check if GITHUB_WORKSPACE is set, if not, set gits_folder to /tmp/gits
if [ -z "${GITHUB_WORKSPACE}" ]; then
    gits_folder="${GITHUB_WORKSPACE}/tmp/gits" # without last /
else
    gits_folder="/tmp/gits" # without last /
fi

#If not LOCAL set branch to main
rd_branch="main"
flathub_target_repo='flathub/net.retrodeck.retrodeck'

# RetroDECK components repo to take the components from
components_repo='RetroDECK/components'

release_version=

# Remove existing gits_folder if it exists and create a new one
if [ -d "$gits_folder" ] ; then
    rm -rf "$gits_folder"
fi
mkdir -vp "$gits_folder"
cd "$gits_folder" && echo "Moving in $gits_folder" || exit 1

# Remove existing flathub and RetroDECK directories if they exist
if [ -d flathub ]; then
    rm -rf "$gits_folder/flathub"
fi
if [ -d flathub ]; then
    rm -rf "$gits_folder/RetroDECK"
fi

# Clone the flathub repository (always). If --local is set, overlay local contents after cloning.
# Clone flathub
git clone --depth=1 --recursive "https://github.com/$flathub_target_repo.git" "$gits_folder/flathub"

if [ "$LOCAL" -eq 1 ]; then
    echo "Overlaying local flathub contents from: $LOCAL_PATH (excluding .github and .git)"
    if [ ! -d "$LOCAL_PATH" ]; then
        echo "ERROR: local path '$LOCAL_PATH' does not exist" && exit 1
    fi
    # Copy local repo contents on top of the cloned repo (preserve .git so push works)
    rsync -a --delete --exclude='.github' --exclude='.git' "$LOCAL_PATH/" "$gits_folder/flathub/"
fi

# Get RetroDECK repository (use local when --local)
if [ "$LOCAL" -eq 1 ]; then
    echo "Using local RetroDECK repository from: $LOCAL_PATH"
    if [ -d "$LOCAL_PATH" ] && [ -f "$LOCAL_PATH/net.retrodeck.retrodeck.yml" ]; then
        # Copy the local RetroDECK repo into the temp workspace
        rsync -a --delete --exclude='.github' "$LOCAL_PATH/" "$gits_folder/RetroDECK/"
    else
        echo "Warning: $LOCAL_PATH does not appear to contain a RetroDECK repo, falling back to remote clone"
        git clone --depth=1 --recursive "https://github.com/$components_repo.git" "$gits_folder/RetroDECK"
    fi
else
    # Always get RetroDECK repository fresh
    git clone --depth=1 --recursive "https://github.com/$components_repo.git" "$gits_folder/RetroDECK"
fi

# Get the latest release name, preferring prereleases if available and published after 2025-01-01
release_name=$(curl -s "https://api.github.com/repos/$components_repo/releases" | jq -r '[.[] | select(.prerelease == true and (.published_at | fromdateiso8601) > 1735689600)][0].tag_name // empty')
if [ -z "$release_name" ]; then
    release_name=$(curl -s https://api.github.com/repos/$components_repo/releases/latest | jq -r .tag_name)
fi
echo "Using release: $release_name"

# Checkout the main branch in the RetroDECK repository
cd "$gits_folder/RetroDECK" && echo "Moving in $gits_folder/RetroDECK" && git checkout "$rd_branch"

# Extract release_version from net.retrodeck.retrodeck.metainfo.xml using xmlstarlet
# Selector: component.releases.release.version
release_version=""
if command -v xmlstarlet >/dev/null 2>&1; then
    if [ -f "net.retrodeck.retrodeck.metainfo.xml" ]; then
        release_version=$(xmlstarlet sel -t -v '(/component/releases/release/@version)[1]' net.retrodeck.retrodeck.metainfo.xml 2>/dev/null | tr -d '[:space:]') || true
        if [ -z "$release_version" ]; then
            echo "Warning: could not extract release_version from metainfo (empty)" >&2
        else
            echo "Detected release_version from metainfo: $release_version"
        fi
    else
        echo "Warning: metainfo file not found: net.retrodeck.retrodeck.metainfo.xml" >&2
    fi
else
    echo "Warning: xmlstarlet not installed; cannot extract release_version" >&2
fi
# Fallback to release_name if we couldn't parse a version
if [ -z "$release_version" ]; then
    release_version="$release_name"
    echo "Using fallback release_version: $release_version"
fi

# Create a new branch in the flathub repository with the release name
cd "$gits_folder"/flathub && echo "Moving in $gits_folder/flathub" || exit 1
git checkout -b "$release_name"
echo "Current directory: $(pwd)"
ls -lah

# Remove all files in the flathub repository and clean the git index
git rm -rf *
git clean -fxd # restoring git index

# Copy all files from the RetroDECK repository to the flathub repository
cp -rfv "$gits_folder/RetroDECK/"* automation_tools "$gits_folder/flathub/"

cd "$gits_folder/flathub" && echo "Moving in $gits_folder/flathub" || exit 1
ls -lah

# Create the manifest for flathub
manifest='net.retrodeck.retrodeck.yml'
cp "$gits_folder/RetroDECK/net.retrodeck.retrodeck.yml" "$manifest"

# Fetch the asset list from the RetroDECK release (tag), fallback to latest
release_json=$(curl -s "https://api.github.com/repos/$components_repo/releases/tags/$release_name")
if echo "$release_json" | jq -e '.message == "Not Found"' >/dev/null 2>&1; then
  release_json=$(curl -s "https://api.github.com/repos/$components_repo/releases/latest")
fi

# Extract release link for logging
release_html=$(echo "$release_json" | jq -r '.html_url // empty')
if [ -n "$release_html" ]; then
  echo "Found release: $release_name -> $release_html"
else
  echo "Found release tag: $release_name (no html_url found in API response)"
fi


# Generate install-components sources from release assets
# For each non-.sha asset in the release, add a `type: file` source with url and sha256
# The SHA is read from the corresponding `.sha` file (either as a separate asset or via the -asset.sha URL)
echo "Generating install-components sources from release assets..."
mapfile -t assets < <(echo "$release_json" | jq -r '.assets[]? | select(.name | test("\\.sha$") | not) | @base64')
if [ "${#assets[@]}" -gt 0 ]; then
  sources_entries=""
  for a in "${assets[@]}"; do
    name=$(echo "$a" | base64 --decode | jq -r '.name')
    url=$(echo "$a" | base64 --decode | jq -r '.browser_download_url')

    # Prefer an explicitly uploaded .sha asset if present
    sha_url=$(echo "$release_json" | jq -r --arg s "${name}.sha" '.assets[]? | select(.name == $s) | .browser_download_url // empty')
    if [ -z "$sha_url" ]; then
      sha_url="https://github.com/$components_repo/releases/download/$release_name/${name}.sha"
    fi

    sha=$(curl -sL "$sha_url" | awk '{print $1; exit}')
    if [ -z "$sha" ]; then
      echo "Warning: could not fetch sha for $name (tried $sha_url)"
      sha=""
    fi

    sources_entries+="        - type: file\n          url: ${url}\n          sha256: ${sha}\n          dest: components\n"
  done

  # Ensure a trailing newline after the generated entries so the next manifest section is separated
  sources_entries+=$'\n'

  # Replace only the sources: sub-block inside install-components (preserve headers and other keys)
  awk -v newentries="$sources_entries" '
    BEGIN{in_install=0; inserted=0; skipping=0}
    /^  - name: install-components/ { print; in_install=1; next }

    in_install {
      if (/^[[:space:]]*sources:/) {
        print "    sources:";
        n = split(newentries, lines, "\n");
        for (i=1;i<=n;i++) if (length(lines[i])) print lines[i];
        print "";
        skipping=1; next
      }

      if (skipping) {
        if (/^  - name:/) { skipping=0; in_install=0; print; next }
        # Skip old source entries
        next
      }

      # If we reach next module header without seeing sources, insert them first
      if (/^  - name:/ && inserted==0) {
        print "    sources:";
        n = split(newentries, lines, "\n");
        for (i=1;i<=n;i++) if (length(lines[i])) print lines[i];
        print "";
        inserted=1
      }

      print; next
    }

    { print }
  ' "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"
else
  echo "No release assets found to populate install-components sources. Leaving manifest as-is."
fi



# Create a flathub.json file specifying the architecture
cat << EOF >> flathub.json
{
"only-arches": ["x86_64"]
}
EOF

echo "Resulting manifest:"
cat "$manifest"

# If running in a GitHub workflow, configure git and authenticate with GitHub
if [ -n "${GITHUB_WORKFLOW}" ] && [ "$DRY_RUN" -eq 0 ]; then
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_MAIL"
    git config --global credential.helper store
    gh auth login
# If not in a GitHub workflow, prompt the user for git configuration if not already set
elif [ "$DRY_RUN" -eq 0 ] && [[ -z $(git config --get user.name) || -z $(git config --get user.email) ]]; then
    read -p "No git user.name set, please enter your name: " git_username
    git config --local user.name "$git_username"
    read -p "No git user.email set, please enter your email: " git_email
    git config --local user.email "$git_email"
fi

# Commit the changes and push to the new branch
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN enabled: skipping git commit/push/auth."
  echo "Generated changes are in: $gits_folder/flathub (branch: $release_name)"
else
  cd "$gits_folder/flathub" || exit 1
  git add .
  git commit -m "Update RetroDECK to v$release_version from RetroDECK/$rd_branch"

  if [ "$LOCAL" -eq 1 ]; then
    echo "Git remotes in $gits_folder/flathub:"
    git remote -v || true

    # Use same push logic as the non-local case: when running in GitHub Actions, set origin to the authenticated URL.
    if [ -n "${GITHUB_WORKFLOW}" ]; then
      if [ -z "${GH_TOKEN}" ]; then
        echo "ERROR: GH_TOKEN not set; cannot authenticate to push to flathub" && exit 1
      fi
      git remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/${flathub_target_repo}"
      git push --force origin "$release_name"
    else
      git push --force "https://github.com/${flathub_target_repo}" "$release_name"
    fi
  else
    # Push the changes to the remote repository, using authentication if in a GitHub workflow
    echo "Git remotes in $gits_folder/flathub:"
    git remote -v || true
    if [ -n "${GITHUB_WORKFLOW}" ]; then
      if [ -z "${GH_TOKEN}" ]; then
        echo "ERROR: GH_TOKEN not set; cannot authenticate to push to flathub" && exit 1
      fi
      git remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/${flathub_target_repo}"
      git push --force origin "$release_name"
    else
      git push --force "https://github.com/${flathub_target_repo}" "$release_name"
    fi
  fi
fi

