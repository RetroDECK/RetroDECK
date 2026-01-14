#!/bin/bash

echo "Welcome to RetroDECK Builder"
echo ""

## ENVIRONMENT SETUP

git config protocol.file.allow always

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]]; then
    echo "This branch is not main, enabling cooker mode"
    IS_COOKER="true"
fi

# Parse arguments
for arg in "$@"; do
    case $arg in
        --cicd)
            echo "Running in CI/CD mode"
            CICD="true"
            ROOT_FOLDER=${GITHUB_WORKSPACE}
            ;;
        --no-artifacts)
            echo "Skipping artifact generation"
            NO_ARTIFACTS="true"
            ;;
        --no-bundle)
            echo "Skipping bundle creation"
            NO_BUNDLE="true"
            ;;
        --no-build)
            echo "No build mode enabled: no build will be actually made"
            NO_BUILD="true"
            ;;
        --force-main)
            echo "Forcing main mode"
            unset IS_COOKER
            ;;
        --force-cooker)
            echo "Forcing cooker mode"
            IS_COOKER="true"
            ;;
        --ccache)
            echo "Enabling CCACHE mode"
            FLATPAK_BUILDER_CCACHE="--ccache"
            ;;
        --flatpak-builder-args=*)
            FLATPAK_BUILD_EXTRA_ARGS="${arg#*=}"
            echo "Additional Flatpak Builder arguments: $FLATPAK_BUILD_EXTRA_ARGS"
            ;;
        --help|-h)
            echo "RetroDECK Builder"
            echo ""
            echo "This script builds the RetroDECK Flatpak package locally or via CI/CD."
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --cicd                      Run in CI/CD mode"
            echo "  --no-artifacts              Skip Flatpak's artifact generation"
            echo "  --no-bundle                 Skip Flatpak's bundle creation (.flatpak file)"
            echo "  --no-build                  Enable no build mode, useful for debugging"
            echo "  --force-main                Force main mode, overriding branch detection"
            echo "  --force-cooker              Force cooker mode, overriding branch detection"
            echo "  --ccache                    Enable CCACHE mode for Flatpak Builder"
            echo "  --flatpak-builder-args=\"\"   Pass additional arguments to Flatpak Builder"
            echo "  --help, -h                  Display this help message"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            ;;
    esac
done

manifest_filename="net.retrodeck.retrodeck.yml"

# Determine the root folder
if [[ -z "$ROOT_FOLDER" ]]; then
    manifest_path=$(find . -maxdepth 1 -name "$manifest_filename" -print -quit)
    if [[ -z "$manifest_path" ]]; then
        # Try searching recursively if not found in current directory
        manifest_path=$(find . -name "$manifest_filename" -print -quit)
        if [[ -z "$manifest_path" ]]; then
            echo "Error: $manifest_filename not found."
            exit 1
        fi
    fi
    ROOT_FOLDER=$(realpath "$(dirname "$manifest_path")")
    echo "ROOT_FOLDER is set to $ROOT_FOLDER"
fi

MANIFEST="$ROOT_FOLDER/$manifest_filename"

# Determine cooker postfix
if [[ "$IS_COOKER" == "true" ]]; then
    POSTFIX="-cooker"
else
    POSTFIX=""
fi

FLATPAK_BUNDLE_NAME="RetroDECK$POSTFIX.flatpak"
BUNDLE_SHA_NAME="RetroDECK.flatpak$POSTFIX.sha"
FLATPAK_ARTIFACTS_NAME="RetroDECK-Artifact$POSTFIX"
OUT_FOLDER="$ROOT_FOLDER/out"

if [[ "$CICD" == "true" ]]; then
    echo "OUT_FOLDER=$OUT_FOLDER" >> "$GITHUB_ENV"
fi

## Use mktemp in CI/CD to store build and repo in /tmp
if [[ "$CICD" == "true" ]]; then
    echo "CI/CD mode detected: using temporary build and repo folders in /tmp."

    ROOT_FOLDER_TMP=$(mktemp -d -p /tmp retrodeck-build-XXXXXX)
    echo "Temporary build root: $ROOT_FOLDER_TMP"

    BUILD_FOLDER_NAME="$ROOT_FOLDER_TMP/retrodeck-flatpak$POSTFIX"
    REPO_FOLDER_NAME="$ROOT_FOLDER_TMP/retrodeck-repo"

    echo "Temporary build folder: $BUILD_FOLDER_NAME"
    echo "Temporary repo folder: $REPO_FOLDER_NAME"
else
    BUILD_FOLDER_NAME="$ROOT_FOLDER/retrodeck-flatpak$POSTFIX"
    REPO_FOLDER_NAME="$ROOT_FOLDER/retrodeck-repo"
fi

## INSTALLING DEPENDENCIES
if [[ "$NO_BUILD" != "true" ]]; then
    echo ""
    echo "Installing dependencies..."
    curl "https://raw.githubusercontent.com/RetroDECK/components-template/main/automation_tools/install_dependencies.sh" | bash
    echo ""
else
    echo "Skipping dependency installation (NO_BUILD mode)."
    curl "https://raw.githubusercontent.com/RetroDECK/components-template/main/automation_tools/install_dependencies.sh" | cat
fi

## BUILD ID GENERATION

# Generate a combination of words to create a build ID eg: "PizzaSushi"
if [[ "$IS_COOKER" == "true" ]]; then
    echo "Cooker mode: generating build ID."
    word1=$(shuf -n 1 $ROOT_FOLDER/automation_tools/codename_wordlist.txt)
    capitalized1="$(tr '[:lower:]' '[:upper:]' <<< ${word1:0:1})${word1:1}"
    word2=$(shuf -n 1 $ROOT_FOLDER/automation_tools/codename_wordlist.txt)
    capitalized2="$(tr '[:lower:]' '[:upper:]' <<< ${word2:0:1})${word2:1}"
    # Exporting build ID as a variable
    export BUILD_ID="$capitalized1$capitalized2"

    # creating the ./buildid file
    echo "$BUILD_ID" > "$ROOT_FOLDER/buildid"

    # Adding the buildid to the GitHub environment variables
    if [[ "$CICD" == "true" ]]; then
        echo "BUILD_ID=$BUILD_ID" >> $GITHUB_ENV
    fi
    echo "Build ID: \"$BUILD_ID\""
fi

## VERSION EXTRACTION

# Extract the version number from the METAINFO XML file
VERSION=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" net.retrodeck.retrodeck.metainfo.xml)

# Extracting verision from METAINFO file
if [[ "$IS_COOKER" == "true" ]]; then
    VERSION="cooker-$VERSION-$BUILD_ID"
fi # Otherwise, if we're on main, use the version number as is

# Writing version in the GitHub environment
if [[ "$CICD" == "true" ]]; then
    echo "VERSION=$VERSION" >> $GITHUB_ENV
    echo "VERSION=$VERSION" >> $GITHUB_OUTPUT
fi

# Creating a version file for RetroDECK Framework to be included in the build
echo "$VERSION" > $ROOT_FOLDER/version

echo "Now building: RetroDECK $VERSION"
echo ""

MANIFEST_REWORKED="${MANIFEST%.*}.reworked.yml"
cp -f "$MANIFEST" "$MANIFEST_REWORKED"

# Checking how the user wants to manage the caches
# this exports a variable named use_cache that is used by manifest_placeholder_replacer script
if [[ "$CICD" != "true" ]]; then
    echo "Do you want to clear the build cache?"
    read -rp "[y/N] " clear_cache
    clear_cache=${clear_cache:-N}
    if [[ "$clear_cache" =~ ^[Yy]$ ]]; then
        rm -rf "$ROOT_FOLDER/$BUILD_FOLDER_NAME" "$ROOT_FOLDER/.flatpak-builder" "$ROOT_FOLDER/$REPO_FOLDER_NAME" "$ROOT_FOLDER/buildid" "$ROOT_FOLDER/version"
        echo "Build cache cleared."
    fi
else
    export use_cache="false"
fi

# Add portal permission in cooker mode
if [[ "$IS_COOKER" == "true" ]]; then
    sed -i '/finish-args:/a \ \ - --talk-name=org.freedesktop.Flatpak' "$MANIFEST_REWORKED"
    echo "Added update portal permission (cooker)."
fi

## BUILD TIME: ccache config

# Checking if the user wants to use ccache, disabled in CI/CD mode
if [[ "$CICD" != "true" && "$FLATPAK_BUILDER_CCACHE" == "--ccache" ]]; then
    if command -v ccache &>/dev/null; then
        export CC="ccache gcc"
        export CXX="ccache g++"
        echo "ccache mode enabled."
    else
        echo "ccache not installed, skipping."
    fi
else
    echo "Skipping ccache setup."
fi

if [[ "$NO_BUILD" != "true" ]]; then
    mkdir -vp "$REPO_FOLDER_NAME" "$BUILD_FOLDER_NAME"
else
    echo "Skipping folder creation (NO_BUILD)."
    echo "\"$REPO_FOLDER_NAME\""
    echo "\"$BUILD_FOLDER_NAME\""
fi

if [[ "$NO_BUILD" == "true" ]]; then
    echo "Skipping component download (NO_BUILD)."
    return
else
    if [[ "$CICD" == "true" ]]; then
        "$ROOT_FOLDER/automation_tools/manage_components.sh" --cicd "$ROOT_FOLDER/components"
    else
        "$ROOT_FOLDER/automation_tools/manage_components.sh" "$ROOT_FOLDER/components"
    fi
fi

mkdir -vp "$OUT_FOLDER"

# Flatpak builder command
# Pass the args to Flatpak Builder
if [[ -n "$FLATPAK_BUILD_EXTRA_ARGS" ]]; then
    echo "Passing additional args to flatpak builder: $FLATPAK_BUILD_EXTRA_ARGS"
    echo ""
fi

if [[ -f "$MANIFEST_REWORKED" ]]; then
    echo "Using reworked manifest: $MANIFEST_REWORKED"
else
    echo "WARNING: Reworked manifest not found, using original manifest: $MANIFEST"
    sleep 10
    MANIFEST_REWORKED="$MANIFEST"
fi

command="flatpak-builder --user --force-clean $FLATPAK_BUILD_EXTRA_ARGS \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo=\"$REPO_FOLDER_NAME\" $FLATPAK_BUILDER_CCACHE \
    \"$BUILD_FOLDER_NAME\" \
    \"$MANIFEST_REWORKED\""

# Execute the build command
if [[ "$NO_BUILD" != "true" ]]; then
    echo ""
    echo "---------------------------------------"
    echo "  Starting manifest build process..."
    echo "---------------------------------------"
    echo -e "Building manifest file $MANIFEST_REWORKED with command:\n$command"
    echo ""
    eval $command

    # Cleanup before bundle
    echo ""
    echo "Cleaning up build and cache to free disk space before bundle..."
    rm -rf "$BUILD_FOLDER_NAME" "$ROOT_FOLDER/.flatpak-builder"
    df -h

    # Create the Flatpak bundle
    echo ""
    echo "Creating the Flatpak bundle..."
    if ! flatpak build-bundle "$REPO_FOLDER_NAME" "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME" net.retrodeck.retrodeck; then
        echo "Error: Failed to create Flatpak bundle ($OUT_FOLDER/$FLATPAK_BUNDLE_NAME)" >&2
        echo "Listing output folder for debugging:"
        ls -la "$OUT_FOLDER" || true
        echo "Disk usage info:"
        df -h
        exit 1
    fi

    # Verify bundle exists and is not empty
    if [[ ! -f "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME" || ! -s "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME" ]]; then
        echo "Error: Flatpak bundle was not created or is empty: $OUT_FOLDER/$FLATPAK_BUNDLE_NAME" >&2
        echo "Listing output folder for debugging:"
        ls -la "$OUT_FOLDER" || true
        echo "Disk usage info:"
        df -h
        exit 1
    fi

    sha256sum "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME" > "$OUT_FOLDER/$BUNDLE_SHA_NAME"

    echo ""
    if [[ "$NO_ARTIFACTS" != "true" ]]; then   
        # Generate final artifact archive
        echo "Generating artifacts archive..."
        tar -czf "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz" -C "$OUT_FOLDER" .
        ARTIFACTS_HASH=($(sha256sum "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz"))
        echo "$ARTIFACTS_HASH" > "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.sha"
        echo "Artifacts archive created."
    else
        echo "Skipping artifact generation as no-artifacts flag is set."
    fi

    
else
    echo "Skipping build (NO_BUILD)."
    # Create fake bundle, artifacts and sha if they don't exist
    if [[ ! -f "$OUT_FOLDER/$BUNDLE_SHA_NAME" ]]; then echo "fake bundle sha" > "$OUT_FOLDER/$BUNDLE_SHA_NAME"; fi
    if [[ ! -f "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME" ]]; then echo "fake bundle" > "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME"; fi
    if [[ ! -f "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz" ]]; then echo "fake artifact" > "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz"; fi
    if [[ ! -f "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.sha" ]]; then echo "fake artifacts sha" > "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.sha"; fi
fi

# Final cleanup in CI/CD
if [[ "$CICD" == "true" && "$NO_BUILD" != "true" ]]; then
    echo ""
    echo "---------------------------------------"
    echo "  Cleanup for CI/CD to free disk space"
    echo "---------------------------------------"

    rm -rf "$BUILD_FOLDER_NAME" "$REPO_FOLDER_NAME" "$ROOT_FOLDER_TMP" "/tmp/retrodeck-build-"*
    rm -rf "$ROOT_FOLDER/.flatpak-builder"
    df -h
fi

echo ""
echo "RetroDECK $VERSION's build completed successfully!"
echo "Generated files are in $OUT_FOLDER"
ls "$OUT_FOLDER"

# Optional install prompt
read -rp "Do you want to install RetroDECK Flatpak? [y/N] " install_input
install_input=${install_input:-N}
if [[ "$install_input" =~ ^[Yy]$ ]]; then
    if flatpak list --app | grep -q "net.retrodeck.retrodeck"; then
        echo "Updating existing installation..."
    fi
    read -rp "Install as user or system? [u/s] " install_type
    install_type=${install_type:-u}
    INSTALL_SCOPE="--user"
    [[ "$install_type" =~ ^[Ss]$ ]] && INSTALL_SCOPE="--system"

    flatpak install -y $INSTALL_SCOPE "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME"
    echo "RetroDECK Flatpak installed successfully!"
fi

echo ""
echo "Build process completed."
