#!/bin/bash

echo "Welcome to RetroDECK Builder"
echo ""

## ENVIRONFENT SETUP

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

# Determine the root folder
if [[ -z "$ROOT_FOLDER" ]]; then
    ROOT_FOLDER=$(find ./ .. -name "net.retrodeck.retrodeck.yml" -print -quit)
    if [[ -z "$ROOT_FOLDER" ]]; then
        echo "Error: net.retrodeck.retrodeck.yml not found."
        exit 1
    fi
    ROOT_FOLDER=$(dirname "$ROOT_FOLDER")
    echo "ROOT_FOLDER is set to $ROOT_FOLDER"
fi

MANIFEST="$ROOT_FOLDER/net.retrodeck.retrodeck.yml"
REPO_FOLDER_NAME="retrodeck-repo"

# Determinating the flatpak build environment artifacts
if [[ "$IS_COOKER" == "true" ]]; then
    POSTFIX="-cooker"
fi
FLATPAK_BUNDLE_NAME="RetroDECK$POSTFIX.flatpak"
BUILD_FOLDER_NAME=retrodeck-flatpak$POSTFIX
BUNDLE_SHA_NAME="RetroDECK.flatpak$POSTFIX.sha"
FLATPAK_ARTIFACTS_NAME="RetroDECK-Artifact$POSTFIX"
OUT_FOLDER="$ROOT_FOLDER/out"

if [[ "$CICD" == "true" ]]; then
    echo "OUT_FOLDER=$OUT_FOLDER" >> $GITHUB_ENV
fi

## INSTALLING DEPENDENCIES

echo ""
echo "Installing dependencies..."
curl "https://raw.githubusercontent.com/RetroDECK/components-template/main/automation_tools/install_dependencies.sh" | bash
echo ""

## BUILD ID GENERATION

# Generate a combination of words to create a build ID eg: "PizzaSushi"
if [[ "$IS_COOKER" == "true" ]]; then
    echo "Cooker mode is enabled, generating a cooker-specific build ID"
    word1=$(shuf -n 1 $ROOT_FOLDER/automation_tools/codename_wordlist.txt)
    capitalized_word1="$(tr '[:lower:]' '[:upper:]' <<< ${word1:0:1})${word1:1}"
    word2=$(shuf -n 1 $ROOT_FOLDER/automation_tools/codename_wordlist.txt)
    capitalized_word2="$(tr '[:lower:]' '[:upper:]' <<< ${word2:0:1})${word2:1}"

    # Exporting build ID as a variable
    export BUILD_ID="$capitalized_word1$capitalized_word2"

    # creating the ./buildid file
    echo $BUILD_ID > $ROOT_FOLDER/buildid

    # Adding the buildid to the GitHub environment variables
    if [[ "$CICD" == "true" ]]; then
        echo "BUILD_ID=$BUILD_ID" >> $GITHUB_ENV
    fi

    echo "Build ID is: \"$BUILD_ID\""
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
fi

# Creating a version file for RetroDECK Framework to be included in the build
echo "$VERSION" > $ROOT_FOLDER/version

echo "Now building: RetroDECK $VERSION"
echo ""

# Backing up the manifest before the placeholder replacement
cp "$MANIFEST" "$MANIFEST.bak"

# Checking how the user wants to manage the caches
# this exports a variable named use_cache that is used by manifest_placeholder_replacer script
if [[ "$CICD" != "true" ]]; then
    read -rp "Do you want to use the hashes cache? If you're unsure just say no [Y/n] " use_cache_input
    use_cache_input=${use_cache_input:-Y}
    if [[ "$use_cache_input" =~ ^[Yy]$ ]]; then
        export use_cache="true"
    else
        export use_cache="false"
        rm -f "placeholders.cache"
    fi

    echo "Do you want to clear the build cache?"
    read -rp "Keeping the build cache can speed up the build process, but it might cause issues and should be cleared occasionally [y/N] " clear_cache_input
    clear_cache_input=${clear_cache_input:-N}
    if [[ "$clear_cache_input" =~ ^[Yy]$ ]]; then
        # User chose to clear the build cache
        echo "Clearing build cache..."
        rm -rf "$ROOT_FOLDER/{$BUILD_FOLDER_NAME,.flatpak-builder}"
    fi
else
    echo "Skipping cache usage prompt as CI/CD mode is enabled."
    export use_cache="false"
fi

# Executing the placeholder replacement script
source "$ROOT_FOLDER/automation_tools/manifest_placeholder_replacer.sh"
echo "Manifest placeholders replaced done"
echo ""

# Adding the update portal permission to the cooker flatpak to allow the framework to update RetroDECK
# This is not allowed on Flathub
if [[ "$IS_COOKER" == "true" ]]; then
    sed -i '/finish-args:/a \ \ - --talk-name=org.freedesktop.Flatpak' "$MANIFEST"
    echo ""
    echo "Added update portal permission to manifest"
    echo ""
fi

## BUILD TIME

# Checking if the user wants to use ccache, disabled in CI/CD mode
if [[ "$CICD" != "true" ]]; then
    if [[ "$FLATPAK_BUILDER_CCACHE" == "--ccache" ]]; then
        if ! command -v ccache &> /dev/null; then
            echo "Compiler cache (ccache) is not installed. Install it to be able to use the cache and speed up your builds"
        else
            export CC="ccache gcc"
            export CXX="ccache g++"
            echo "ccache mode is enabled and configured"
        fi
    fi
else
    echo "Skipping ccache configuration as CI/CD mode is enabled."
fi

if [[ "$NO_BUILD" != "true" ]]; then
    mkdir -vp "$ROOT_FOLDER/$REPO_FOLDER_NAME"
    mkdir -vp "$ROOT_FOLDER/$BUILD_FOLDER_NAME"
else
    echo "Skipping folder creation as NO_BUILD mode is enabled."
    echo -e "The following paths should have been created:"
    echo "\"$ROOT_FOLDER/$REPO_FOLDER_NAME\""
    echo "\"$ROOT_FOLDER/$BUILD_FOLDER_NAME\""
    echo ""
fi

mkdir -vp "$OUT_FOLDER"

# Pass the args to Flatpak Builder
if [[ -n "$FLATPAK_BUILD_EXTRA_ARGS" ]]; then
    echo "Passing additional args to flatpak builder: $FLATPAK_BUILD_EXTRA_ARGS"
    echo ""
fi

command="flatpak-builder --user --force-clean $FLATPAK_BUILD_EXTRA_ARGS \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo=\"$ROOT_FOLDER/$REPO_FOLDER_NAME\" $FLATPAK_BUILDER_CCACHE\
    \"$ROOT_FOLDER/$BUILD_FOLDER_NAME\" \
    \"$MANIFEST\""

# Echo the command for verification
echo -e "Building manifest with command:\n$command"
echo ""

# Execute the build command
if [[ "$NO_BUILD" != "true" ]]; then
    eval $command
    # Building the bundle RetroDECK.flatpak after the download and build steps are done
    flatpak build-bundle "$ROOT_FOLDER/$REPO_FOLDER_NAME" "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME" net.retrodeck.retrodeck
    sha256sum "$ROOT_FOLDER/$FLATPAK_BUNDLE_NAME" >> "$OUT_FOLDER/$BUNDLE_SHA_NAME"
else
    echo "Skipping build as NO_BUILD mode is enabled."
    echo "Generating fake artifacts for testing purposes or using the old ones if available"
    if [[ ! -f "$OUT_FOLDER/$BUNDLE_SHA_NAME" ]]; then
        echo "fake build" > "$OUT_FOLDER/$BUNDLE_SHA_NAME"
    fi
    if [[ ! -f "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME" ]]; then
        echo "fake bundle" > "$OUT_FOLDER/$FLATPAK_BUNDLE_NAME"
    fi
fi

# Preparing the RetroDECK flatpak's artifacts in case we need to export them to Flathub
if [[ "$NO_ARTIFACTS" != "true" && "$NO_BUILD" != "true" ]]; then
    tar -czf "$ROOT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz" -C "$OUT_FOLDER" .
    ARTIFACTS_HASH=($(sha256sum $OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz))
    echo "$ARTIFACTS_HASH" > "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.sha"
else
    echo "Skipping Flathub artifacts preparation due to user preference or no-build mode."
    echo "Generating fake artifacts for testing purposes or using the old ones if available"
    if [[ ! -f "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.sha" ]]; then
        echo "foo" > "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.sha"
    fi
    if [[ ! -f "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz" ]]; then
        echo "fake artifacts" > "$OUT_FOLDER/$FLATPAK_ARTIFACTS_NAME.tar.gz"
    fi
fi

echo "Restoring the original manifest"
mv -f "$MANIFEST.bak" "$MANIFEST"

echo ""
echo "RetroDECK $VERSION's build completed successfully!"
echo "Generated files are in $OUT_FOLDER"
ls "$OUT_FOLDER"