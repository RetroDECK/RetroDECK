#!/bin/bash
# Builds Flatpak bundles with variant-specific customizations

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

METAINFO_FILE="net.retrodeck.retrodeck.metainfo.xml"
MANIFEST_FILE="net.retrodeck.retrodeck.yml"
CODENAME_WORDLIST="automation_tools/codename_wordlist.txt"
COMPONENTS_REPO="RetroDECK/components"
COMPONENT_SOURCES_FILE="component-sources.json"
APPLICATION_SOURCES_FILE="application-sources.json"
APPLICATION_REPO="RetroDECK/RetroDECK"
VERSION_FILE="version"
OUT_FOLDER="output"

COUNTERTOP_CORE_COMPONENTS=(
  "framework"
  "es-de"
)

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
  local build_type=""
  local use_ccache=false
  local no_bundle=false
  local dry_run=false
  local extra_builder_args=""
  local download_components_tag=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-flatpak)
        build_type="$2"
        shift 2
        ;;
      --ccache)
        use_ccache=true
        shift
        ;;
      --no-bundle)
        no_bundle=true
        shift
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      --flatpak-builder-args)
        extra_builder_args="$2"
        shift 2
        ;;
      --download-components)
        download_components_tag="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown argument '$1'"
        exit 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ -z "$build_type" ]]; then
    echo "Error: --build-flatpak <type> is required"
    exit 1
  fi

  # Validate build type
  if [[ ! "$build_type" =~ ^(full|epicure|countertop)$ ]]; then
    echo "Error: Invalid build type '$build_type'. Must be one of: full, epicure, countertop"
    exit 1
  fi

  # Enforce mutual exclusivity
  if [[ "$no_bundle" == true && "$dry_run" == true ]]; then
    echo "Error: --no-bundle and --dry-run cannot be used together"
    exit 1
  fi

  BUILD_TYPE="$build_type"
  USE_CCACHE="$use_ccache"
  NO_BUNDLE="$no_bundle"
  DRY_RUN="$dry_run"
  EXTRA_BUILDER_ARGS="$extra_builder_args"
  DOWNLOAD_COMPONENTS_TAG="$download_components_tag"
}

# =============================================================================
# Dependency Installation
# =============================================================================

install_dependencies() {
  local pkg_mgr=""

  # rpm-ostree must be checked before dnf because dnf wrapper exists on rpm-ostree distros
  for potential_pkg_mgr in apt pacman rpm-ostree dnf; do
    command -v "$potential_pkg_mgr" &> /dev/null && pkg_mgr="$potential_pkg_mgr" && break
  done

  case "$pkg_mgr" in
    apt)
      sudo add-apt-repository -y ppa:flatpak/stable
      sudo apt update
      sudo apt install -y flatpak flatpak-builder p7zip-full xmlstarlet bzip2 curl jq unzip
      ;;
    pacman)
      sudo pacman -S --noconfirm flatpak flatpak-builder p7zip xmlstarlet bzip2 curl jq unzip
      ;;
    rpm-ostree)
      echo "Error: rpm-ostree distros are not supported for direct builds. Try using a distrobox."
      exit 1
      ;;
    dnf)
      sudo dnf install -y flatpak flatpak-builder p7zip p7zip-plugins xmlstarlet bzip2 curl jq unzip
      ;;
    *)
      echo "Error: No supported package manager found. Please open an issue."
      exit 1
      ;;
  esac

  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak remote-add --user --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
}

# =============================================================================
# Environment Detection
# =============================================================================

get_root_folder() {
  git rev-parse --show-toplevel
}

get_branch() {
  git rev-parse --abbrev-ref HEAD
}

sanitize_branch() {
  echo "${1//\//-}"
}

is_ci() {
    [[ "$CI" == "true" ]]
}

# =============================================================================
# Metainfo Extraction
# =============================================================================

extract_metainfo() {
  local metainfo_file="$1"

  if [[ ! -f "$metainfo_file" ]]; then
    echo "Error: Metainfo file not found at $metainfo_file"
    exit 1
  fi

  APP_ID=$(xmlstarlet sel -t -v "/component/id" "$metainfo_file")
  APP_NAME=$(xmlstarlet sel -t -v "/component/name" "$metainfo_file")
  APP_VERSION=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" "$metainfo_file")

  if [[ -z "$APP_ID" ]]; then
    echo "Error: Could not extract application ID from $metainfo_file"
    exit 1
  fi

  if [[ -z "$APP_NAME" ]]; then
    echo "Error: Could not extract application name from $metainfo_file"
    exit 1
  fi

  if [[ -z "$APP_VERSION" ]]; then
    echo "Error: Could not extract version from $metainfo_file"
    exit 1
  fi
}

# =============================================================================
# Codename Generation
# =============================================================================

generate_codename() {
  local wordlist="$1"
  local words

  if [[ ! -f "$wordlist" ]]; then
    echo "Error: Codename wordlist not found at $wordlist"
    exit 1
  fi

  mapfile -t words < <(shuf -n 2 "$wordlist")
  echo "${words[0]^}${words[1]^}"
}

# =============================================================================
# Version String Construction
# =============================================================================

construct_version_string() {
  local branch="$1"
  local build_type="$2"
  local version="$3"
  local codename="$4"
  local date
  date=$(date +%Y-%m-%d)

  case "$branch" in
    main)
      echo "$version"
      ;;
    cooker)
      case "$build_type" in
        epicure)
          echo "epicure-${version}-${date}"
          ;;
        *)
          echo "cooker-${version}-${codename}-${date}"
          ;;
      esac
      ;;
    *)
      local sanitized_branch
      sanitized_branch=$(sanitize_branch "$branch")
      echo "${sanitized_branch}-${version}-${date}"
      ;;
  esac
}

# =============================================================================
# Component Source Download (for local builds)
# =============================================================================

download_components() {
  local tag="$1"
  local dest="$2"
  local download_url

  # Resolve "latest" tag via GitHub API
  if [[ "$tag" == "latest" ]]; then
    echo "Resolving latest release tag from $COMPONENTS_REPO..."
    tag=$(curl -s "https://api.github.com/repos/${COMPONENTS_REPO}/releases/latest" | jq -r '.tag_name')
    if [[ -z "$tag" || "$tag" == "null" ]]; then
      echo "Error: Could not resolve latest release tag from $COMPONENTS_REPO"
      exit 1
    fi
    echo "Resolved latest release tag: $tag"
  fi

  download_url="https://github.com/${COMPONENTS_REPO}/releases/download/${tag}/${COMPONENT_SOURCES_FILE}"

  echo "Downloading $COMPONENT_SOURCES_FILE from release $tag..."
  if ! curl -fSL -o "$dest" "$download_url"; then
    echo "Error: Failed to download $COMPONENT_SOURCES_FILE from $download_url"
    exit 1
  fi

  echo "Downloaded $COMPONENT_SOURCES_FILE from release $tag"
}

# =============================================================================
# Application Source Generation (for local builds)
# =============================================================================

generate_application_sources() {
  local dest="$1"
  local commit
  commit=$(git rev-parse HEAD)

  echo "Generating $APPLICATION_SOURCES_FILE for commit $commit"

  jq -n --arg url "https://github.com/${APPLICATION_REPO}.git" --arg commit "$commit" '
    [
      {
        "type": "git",
        "url": $url,
        "commit": $commit
      }
    ]
  ' > "$dest"
}

# =============================================================================
# Component Filtering (for countertop builds)
# =============================================================================

filter_components() {
  local sources_file="$1"
  local core_list

  if [[ ! -f "$sources_file" ]]; then
    echo "Error: Component sources file not found at $sources_file"
    exit 1
  fi

  # Build a jq filter array from the core components list
  core_list=$(printf '%s\n' "${COUNTERTOP_CORE_COMPONENTS[@]}" | jq -R . | jq -s .)

  # Filter: keep only objects whose URL filename (without extension) is in the core list
  jq --argjson core "$core_list" '
    [ .[] | select(
      (.url | split("/") | last | split(".") | first) as $name |
      $core | index($name)
    )]
  ' "$sources_file" > "${sources_file}.tmp" && mv "${sources_file}.tmp" "$sources_file"

  echo "Filtered component-sources.json to $(jq length "$sources_file") core components"
}

# =============================================================================
# Flatpak Build
# =============================================================================

build_flatpak() {
  local version_string="$1"
  local build_dir="build"
  local repo_dir="repo"
  local out_folder="$OUT_FOLDER"
  local bundle_name="${APP_NAME// /-}-${version_string}.flatpak"
  local builder_cmd="flatpak-builder --user --force-clean"

  builder_cmd+=" --install-deps-from=flathub"
  builder_cmd+=" --install-deps-from=flathub-beta"
  builder_cmd+=" --repo=\"${repo_dir}\""

  if [[ "$USE_CCACHE" == true ]]; then
    builder_cmd+=" --ccache"
  fi

  if [[ -n "$EXTRA_BUILDER_ARGS" ]]; then
    builder_cmd+=" $EXTRA_BUILDER_ARGS"
  fi

  builder_cmd+=" \"${build_dir}\""
  builder_cmd+=" \"${MANIFEST_FILE}\""

  echo "Building Flatpak with command:"
  echo "$builder_cmd"

  if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run: skipping flatpak-builder"
    return 0
  fi

  eval "$builder_cmd"

  if [[ "$NO_BUNDLE" == true ]]; then
    echo "No-bundle mode: skipping bundle creation"
    return 0
  fi

  mkdir -p "$out_folder"

  echo "Creating bundle: $bundle_name"
  flatpak build-bundle "$repo_dir" "${out_folder}/${bundle_name}" "$APP_ID"

  # Validate bundle was created
  if [[ ! -f "${out_folder}/${bundle_name}" ]]; then
    echo "Error: Bundle file was not created at ${out_folder}/${bundle_name}"
    exit 1
  fi

  echo "Bundle created: ${out_folder}/${bundle_name} ($(du -h "${out_folder}/${bundle_name}" | cut -f1))"

  # Generate SHA hash in CI only
  if is_ci; then
    sha256sum "${out_folder}/${bundle_name}" > "${out_folder}/${bundle_name}.sha"
    echo "SHA256 hash written to ${out_folder}/${bundle_name}.sha"
  fi
}

# =============================================================================
# CI Variable Export
# =============================================================================

export_ci_variables() {
  if is_ci; then
    echo "version=$VERSION_STRING" >> "$GITHUB_OUTPUT"
  fi
}

# =============================================================================
# Main
# =============================================================================

main() {
  parse_args "$@"

  echo "=== Installing dependencies ==="
  install_dependencies

  echo "=== Detecting environment ==="
  ROOT_FOLDER=$(get_root_folder)
  cd "$ROOT_FOLDER" || exit 1
  BRANCH=$(get_branch)
  echo "Root folder: $ROOT_FOLDER"
  echo "Branch: $BRANCH"

  echo "=== Configuring Git ==="
  git config protocol.file.allow always

  echo "=== Extracting metainfo ==="
  extract_metainfo "$ROOT_FOLDER/$METAINFO_FILE"
  echo "App ID: $APP_ID"
  echo "App name: $APP_NAME"
  echo "App version: $APP_VERSION"

  echo "=== Constructing version string ==="
  local codename=""
  if [[ "$BRANCH" == "cooker" && "$BUILD_TYPE" != "epicure" ]]; then
    codename=$(generate_codename "$ROOT_FOLDER/$CODENAME_WORDLIST")
    echo "Generated codename: $codename"
  fi

  VERSION_STRING=$(construct_version_string "$BRANCH" "$BUILD_TYPE" "$APP_VERSION" "$codename")
  echo "Version string: $VERSION_STRING"

  echo "=== Writing version file ==="
  echo "$VERSION_STRING" > "$ROOT_FOLDER/$VERSION_FILE"
  echo "Version written to $VERSION_FILE"

  echo "=== Checking application sources ==="
  local app_sources_path="$ROOT_FOLDER/$APPLICATION_SOURCES_FILE"

  if [[ ! -f "$app_sources_path" ]]; then
    echo "$APPLICATION_SOURCES_FILE not found, generating from local Git state"
    generate_application_sources "$app_sources_path"
  else
    echo "$APPLICATION_SOURCES_FILE already exists, using existing file"
  fi

  echo "=== Checking component sources ==="
  local components_path="$ROOT_FOLDER/$COMPONENT_SOURCES_FILE"

  if [[ -n "$DOWNLOAD_COMPONENTS_TAG" ]]; then
    if [[ -f "$components_path" ]]; then # If a component-sources file already exists
      if is_ci; then # If CI, default to overwriting local file with specified tag file
        echo "CI environment: overwriting existing $COMPONENT_SOURCES_FILE"
        download_components "$DOWNLOAD_COMPONENTS_TAG" "$components_path"
      else # Prompt local user for choice of file to use
        read -r -p "$COMPONENT_SOURCES_FILE already exists. Overwrite with downloaded version? [y/N] " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
          download_components "$DOWNLOAD_COMPONENTS_TAG" "$components_path"
        else
          echo "Keeping existing $COMPONENT_SOURCES_FILE"
        fi
      fi
    else
      download_components "$DOWNLOAD_COMPONENTS_TAG" "$components_path"
    fi
  fi

  if [[ ! -f "$components_path" ]]; then
    echo "Error: $COMPONENT_SOURCES_FILE not found at $components_path"
    echo "Provide the file manually or use --download-components <tag|latest> to download it"
    exit 1
  fi

  echo "=== Filtering components ==="
  if [[ "$BUILD_TYPE" == "countertop" ]]; then
    filter_components "$ROOT_FOLDER/$COMPONENT_SOURCES_FILE"
  else
    echo "No filtering needed for build type: $BUILD_TYPE"
  fi

  echo "=== Building Flatpak ==="
  build_flatpak "$VERSION_STRING"

  echo "=== Exporting CI variables ==="
  export_ci_variables

  echo "=== Build complete ==="
}

main "$@"
