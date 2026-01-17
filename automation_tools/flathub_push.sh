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
    --exclude=*)
      # Append to EXCLUDE_LIST (comma-separated): --exclude=pattern
      EXCLUDE_LIST="${EXCLUDE_LIST:+$EXCLUDE_LIST,}${arg#--exclude=}"
      ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--local[=PATH]] [--exclude=PATTERN]"
      echo "  --dry-run       Run locally but do not commit/push or auth to GitHub."
      echo "  --local[=PATH]  Use an existing local flathub repository (default: current dir); do not clone from GitHub."
      echo "  --exclude=PATTERN  Exclude additional files/dirs from rsync (can be passed multiple times or via EXCLUDE_LIST env var, comma-separated)"
      exit 0
      ;;
  esac
done

# default local path to current dir when --local provided without path
if [ "$LOCAL" -eq 1 ] && [ -z "$LOCAL_PATH" ]; then
  LOCAL_PATH="$PWD"
fi

# Default excludes; can be extended with --exclude flags or EXCLUDE_LIST env var (comma-separated)
# Flathub manifest folder cannot be larger than 25MB, so we need to exclude unnecessary files
EXCLUDES=(.github .git "res" "automation_tools/archive_later" "automation_tools/codename_wordlist.txt" "automation_tools/fetch_components.sh" "automation_tools/flathub_push.sh" "automation_tools/post_build_check.sh" "automation_tools/search_missing_libs.sh" "config" "developer_toolbox" "functions" "tools" "retrodeck_builder.sh")

# If EXCLUDE_LIST is set (either via --exclude flags or environment), append those excludes (comma-separated)
if [ -n "${EXCLUDE_LIST:-}" ]; then
  IFS=',' read -r -a extra_excludes <<< "$EXCLUDE_LIST"
  for e in "${extra_excludes[@]}"; do
    e_trim=$(echo "$e" | xargs)
    if [ -n "$e_trim" ]; then
      EXCLUDES+=("$e_trim")
    fi
  done
fi

# Build rsync exclude options
rsync_exclude_opts=()
for e in "${EXCLUDES[@]}"; do
  rsync_exclude_opts+=(--exclude="$e")
done

# Check if GITHUB_WORKSPACE is set, if not, set gits_folder to /tmp/gits
if [ -z "${GITHUB_WORKSPACE}" ]; then
    gits_folder="${GITHUB_WORKSPACE}/tmp/gits" # without last /
else
    gits_folder="/tmp/gits" # without last /
fi


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
#                             Variables
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#If not LOCAL set branch to main
rd_branch="main"
flathub_target_repo='flathub/net.retrodeck.retrodeck'

# RetroDECK components repo to take the components from
components_repo='RetroDECK/components'

# Release version that will be populated later
release_version="unknown"

# Modules in the manifest where we want to replace the local "." path with a git source poiting to RetroDECK repo
replace_pwd_source=("install-components" "finisher")

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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
#                             Main Script
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Clone the flathub repository (always). If --local is set, overlay local contents after cloning.
# Clone flathub
git clone --depth=1 --recursive "https://github.com/$flathub_target_repo" "$gits_folder/flathub"

if [ "$LOCAL" -eq 1 ]; then
    echo "Overlaying local flathub contents from: $LOCAL_PATH (excluding: ${EXCLUDES[*]})"
    if [ ! -d "$LOCAL_PATH" ]; then
        echo "ERROR: local path '$LOCAL_PATH' does not exist" && exit 1
    fi
    # Copy local repo contents on top of the cloned repo
    rsync -a --delete "${rsync_exclude_opts[@]}" "$LOCAL_PATH/" "$gits_folder/flathub/"
fi

# Get RetroDECK repository (use local when --local)
if [ "$LOCAL" -eq 1 ]; then
    echo "Using local RetroDECK repository from: $LOCAL_PATH"
    if [ -d "$LOCAL_PATH" ] && [ -f "$LOCAL_PATH/net.retrodeck.retrodeck.yml" ]; then
        # Copy the local RetroDECK repo into the temp workspace
        rsync -a --delete "${rsync_exclude_opts[@]}" "$LOCAL_PATH/" "$gits_folder/RetroDECK/"
    else
        echo "Warning: $LOCAL_PATH does not appear to contain a RetroDECK repo, falling back to remote clone"
        git clone --depth=1 --recursive "https://github.com/$components_repo" "$gits_folder/RetroDECK"
    fi
else
    # Always get RetroDECK repository fresh
    git clone --depth=1 --recursive "https://github.com/$components_repo" "$gits_folder/RetroDECK"
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

# Create a new branch in the flathub repository with the release version
cd "$gits_folder"/flathub && echo "Moving in $gits_folder/flathub" || exit 1
git checkout -b "$release_version"
echo "Current directory: $(pwd) (branch: $release_version)"
ls -lah

# Remove all files in the flathub repository and clean the git index
git rm -rf *
git clean -fxd # restoring git index

# Copy all files from the RetroDECK repository to the flathub repository
cp -rfv "$gits_folder/RetroDECK/"* "$gits_folder/flathub/"

# Add "version" file to flathub repo folder
echo "$release_version" >> "$gits_folder/flathub/version"

cd "$gits_folder/flathub" && echo "Moving in $gits_folder/flathub" || exit 1
ls -lah

# Create the manifest for flathub
manifest='net.retrodeck.retrodeck.yml'
cp "$gits_folder/RetroDECK/net.retrodeck.retrodeck.yml" "$manifest"

# Fetch the asset list from the RetroDECK Components release (tag), fallback to latest
release_json=$(curl -s "https://api.github.com/repos/$components_repo/releases/tags/$release_name")
if echo "$release_json" | jq -e '.message == "Not Found"' >/dev/null 2>&1; then
  release_json=$(curl -s "https://api.github.com/repos/$components_repo/releases/latest")
fi

# Extract Components release link for logging
release_html=$(echo "$release_json" | jq -r '.html_url // empty')
if [ -n "$release_html" ]; then
  echo "Found components release: $release_name -> $release_html"
else
  echo "Found components release tag: $release_name (no html_url found in API response)"
fi


# Determine RetroDECK commit/ref to embed in finisher sources (prefer local repo when --local)
retrodeck_commit=""
if [ "$LOCAL" -eq 1 ] && [ -d "${LOCAL_PATH:-}" ] ; then
  if [ -d "$LOCAL_PATH/.git" ]; then
    retrodeck_commit=$(git -C "$LOCAL_PATH" rev-parse --verify HEAD 2>/dev/null || true)
  else
    retrodeck_commit=$(git -C "$LOCAL_PATH" rev-parse --verify HEAD 2>/dev/null || true) || true
  fi
fi

if [ -z "$retrodeck_commit" ] && [ -d "$gits_folder/RetroDECK/.git" ]; then
  retrodeck_commit=$(git -C "$gits_folder/RetroDECK" rev-parse --verify HEAD 2>/dev/null || true)
fi

if [ -z "$retrodeck_commit" ]; then
  retrodeck_commit=$(git ls-remote "https://github.com/RetroDECK/RetroDECK" "$rd_branch" | awk '{print $1; exit}')
fi

retrodeck_commit=${retrodeck_commit:-$release_name}
echo "Using RetroDECK commit/ref: $retrodeck_commit"

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

    # Try to fetch a .sha file and validate it is a real SHA256 (64 hex chars). If not present or invalid,
    # download the asset, compute its sha256, and remove the temporary file.
    sha=$(curl -sL "$sha_url" | awk '{print $1; exit}' || true)
    if ! echo "$sha" | grep -Eq '^[0-9a-fA-F]{64}$'; then
      echo "Warning: could not fetch valid sha for $name (tried $sha_url); computing sha256 from asset..." >&2
      tmpfile=$(mktemp) || tmpfile="/tmp/${name}.tmp"
      if curl -sL -f -o "$tmpfile" "$url"; then
        # compute sha256 and remove the tmpfile
        if command -v sha256sum >/dev/null 2>&1; then
          sha=$(sha256sum "$tmpfile" | awk '{print $1}')
        else
          # fallback to shasum -a 256 if sha256sum not available
          sha=$(shasum -a 256 "$tmpfile" | awk '{print $1}')
        fi
        rm -f "$tmpfile"
        echo "Computed sha256 for $name: $sha" >&2
      else
        echo "Warning: failed to download asset to compute sha for $name (tried $url)" >&2
        rm -f "$tmpfile" || true
        sha=""
      fi
    fi

    sources_entries+="        - type: file\n          url: ${url}\n          sha256: ${sha}\n          dest: components\n"
  done

  # Ensure a trailing newline after the generated entries so the next manifest section is separated
  sources_entries+="        - type: dir\n          path: .\n"

  # Replace only the sources: sub-block inside install-components (preserve headers and other keys)
  awk -v newentries="$sources_entries" '
    BEGIN{in_install=0; inserted=0; skipping=0}
    /^  - name: install-components/ { print; in_install=1; next }

    in_install {
      if (/^[[:space:]]*sources:/) {
        print "    sources:";
        n = split(newentries, lines, "\n");
        for (i=1;i<=n;i++) print lines[i];
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
        for (i=1;i<=n;i++) print lines[i];
        inserted=1
      }

      print; next
    }

    { print }
  ' "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"
else
  echo "No release assets found to populate install-components sources. Leaving manifest as-is."
fi

# Determine RetroDECK commit/ref to embed in finisher sources (prefer local repo when --local)
retrodeck_commit=""
if [ "$LOCAL" -eq 1 ] && [ -d "${LOCAL_PATH:-}" ] ; then
  if [ -d "$LOCAL_PATH/.git" ]; then
    retrodeck_commit=$(git -C "$LOCAL_PATH" rev-parse --verify HEAD 2>/dev/null || true)
  else
    retrodeck_commit=$(git -C "$LOCAL_PATH" rev-parse --verify HEAD 2>/dev/null || true) || true
  fi
fi

if [ -z "$retrodeck_commit" ] && [ -d "$gits_folder/RetroDECK/.git" ]; then
  retrodeck_commit=$(git -C "$gits_folder/RetroDECK" rev-parse --verify HEAD 2>/dev/null || true)
fi

if [ -z "$retrodeck_commit" ]; then
  retrodeck_commit=$(git ls-remote "https://github.com/RetroDECK/RetroDECK" "$rd_branch" | awk '{print $1; exit}')
fi

retrodeck_commit=${retrodeck_commit:-$release_name}
echo "Using RetroDECK commit/ref: $retrodeck_commit"

finisher_entries=$(cat <<-YAML
    sources:
      - type: dir
        path: .
YAML
)

awk -v newentries="$finisher_entries" '
  BEGIN{in_fin=0; inserted=0; skipping=0}
  /^  - name: finisher/ { print; in_fin=1; next }
  in_fin {
    if (/^[[:space:]]*sources:/) {
      print "";
      printf "%s\n", newentries;
      skipping=1; next
    }
    if (skipping) {
      if (/^  - name:/) { skipping=0; in_fin=0; print; next }
      next
    }
    if (/^  - name:/ && inserted==0) {
      print "";
      printf "%s\n", newentries;
      inserted=1
    }
    print; next
  }
  { print }
' "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"

# Replace `- type: dir path: .` with git entry in modules listed in replace_pwd_source
awk -v modules="${replace_pwd_source[*]}" -v repo_url="https://github.com/RetroDECK/RetroDECK" -v commit="${retrodeck_commit}" '
  BEGIN{ split(modules, m, " "); for (i in m) target[m[i]]=1; in_mod=0; in_sources=0 }
  /^[[:space:]]*- name: / {
    name=$0; sub(/^[[:space:]]*- name:[[:space:]]*/, "", name); gsub(/^[ \t]+|[ \t]+$/, "", name);
    if (name in target) in_mod=1; else in_mod=0;
    print; next
  }
  in_mod && /^[[:space:]]*sources:/ { print; in_sources=1; next }
  in_mod && in_sources {
    if (/^[[:space:]]*- type: dir[[:space:]]*$/) {
      getline nextline
      if (nextline ~ /^[[:space:]]*path:[[:space:]]*\.$/) {
        print "        - type: git";
        printf "          url: %s\n", repo_url;
        printf "          commit: %s\n", commit;
        next
      } else {
        print $0; print nextline; next
      }
    }
    if (/^[[:space:]]*- name:/) { in_sources=0 }
  }
  { print }
' "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"

# Remove the 'summary' module entirely from the generated manifest
awk 'BEGIN{del=0}
/^[[:space:]]*- name: summary/ {del=1; next}
{
  if (del) {
    if (/^[[:space:]]*- name:/) { del=0; print; next }
    next
  }
  print
}' "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"

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
  echo "Generated changes are in: $gits_folder/flathub (branch: $release_version)"
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
      git push --force origin "$release_version"
    else
      git push --force "https://github.com/${flathub_target_repo}" "$release_version"
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
      git push --force origin "$release_version"
    else
      git push --force "https://github.com/${flathub_target_repo}" "$release_version"
    fi
  fi

  # Write a small info file into the GitHub workspace so downstream jobs can read it
  if [ -n "${GITHUB_WORKSPACE}" ]; then
    out_file="${GITHUB_WORKSPACE}/flathub_push_info.env"
  else
    out_file="$PWD/flathub_push_info.env"
  fi

  echo "COMPONENT_VERSION=$release_version" > "$out_file" || true
  echo "COMPONENT_RELEASE_URL=${release_html:-}" >> "$out_file" || true
  echo "FLATHUB_BRANCH=$release_version" >> "$out_file" || true
  echo "FLATHUB_BRANCH_URL=https://github.com/${flathub_target_repo}/tree/${release_version}" >> "$out_file" || true
  echo "RETRODECK_COMMIT=${retrodeck_commit:-}" >> "$out_file" || true
fi
