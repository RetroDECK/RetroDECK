#!/bin/bash

# This script downloads the latest components for RetroDECK from the GitHub repository.
# Usage: ./download_components.sh [--manual|--cicd] <components_dir>

# Parse arguments
CICD="false"
COMPONENTS_DIR=""
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --manual)
            CICD="false"
            shift
            ;;
        --cicd)
            CICD="true"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--manual|--cicd] <components_dir>"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    COMPONENTS_DIR="${POSITIONAL_ARGS[0]}"
fi

# Begin main script logic (was previously inside manage_components function)

# Downloading the latest components
if [[ -z "$COMPONENTS_DIR" ]]; then
    echo "Error: COMPONENTS_DIR not specified."
    "$0" --help
    exit 1
fi
mkdir -vp "$COMPONENTS_DIR"

echo "---------------------------------------------"
echo "   Welcome to RetroDECK Components Manager"
echo "---------------------------------------------"

if [[ "$CICD" != "true" ]]; then
    echo "You can download the latest components from RetroDECK/components repository (suggested) or,"
    echo "in case you are building RetroDECK, skip download and provide your own components."
    echo "If you choose to download, you can select between Cooker and Main branches."
    echo "If you choose to provide your own components, make sure to place them in the $COMPONENTS_DIR directory."
    echo "Select components source:"
    echo "  1) Cooker - Default if branch is cooker or not main"
    echo "  2) Main   - Default if branch is main"
    echo "  3) Cloned - Grab the components from a cloned repository"
    echo "  4) Local  - Skip download, provide your own \"$COMPONENTS_DIR\""
    read -rp "Enter choice [1-4]: " components_source
    components_source=${components_source:-$(
        if [[ "$IS_COOKER" == "true" ]]; then echo "1"; else echo "2"; fi
    )}
else
    components_source=""
fi

if [[ "$components_source" == "3" ]]; then
    # Function to copy components from a given directory
    copy_components() {
        local src_dir="$1"
        # Check if at least one artifacts directory exists
        if ! find "$src_dir" -mindepth 2 -maxdepth 2 -type d -name "artifacts" | grep -q .; then
            echo "Error: No artifacts directories found under $src_dir/<component_name>/artifacts."
            exit 1
        fi
        # Copy all .tar.gz and .sha files from all artifacts directories
        find "$src_dir" -mindepth 2 -maxdepth 2 -type d -name "artifacts" | while read -r artifacts_dir; do
            find "$artifacts_dir" -type f \( -name "*.tar.gz" -o -name "*.sha" \) -exec cp -v {} "$COMPONENTS_DIR/" \;
        done
        echo "Components copied from $src_dir to $COMPONENTS_DIR."
        echo "Listing copied components:"
        ls -1 "$COMPONENTS_DIR"
        read -rp "Do you want to continue? [Y/n] " continue_input
        continue_input=${continue_input:-Y}
        if [[ ! "$continue_input" =~ ^[Yy]$ ]]; then
            echo "Aborting as per user choice."
            exit 1
        fi
    }

    if [[ -d "../components" ]]; then
        echo "Found components from ../components."
        read -rp "Do you want to use the components from ../components? [Y/n] " use_cloned
        use_cloned=${use_cloned:-Y}
        if [[ "$use_cloned" =~ ^[Yy]$ ]]; then
            copy_components "../components"
        fi
    else
        read -rp "Please enter the path to your components folder: " user_components_dir
        user_components_dir=${user_components_dir:-}
        if [[ -z "$user_components_dir" || ! -d "$user_components_dir" ]]; then
            echo "Error: Directory not specified or does not exist."
            exit 1
        fi
        copy_components "$user_components_dir"
    fi
fi
elif [[ "$components_source" == "4" ]]; then
    echo "Using local components. Please place your components in $COMPONENTS_DIR."
    if [[ ! -d "$COMPONENTS_DIR" ]]; then
        echo "Error: Components directory \"$COMPONENTS_DIR\" does not exist. Please create it and add your components."
        exit 1
    fi
else
    # Determine which release to download based on user selection or CI/CD mode
    if [[ "$CICD" == "true" ]]; then
        if [[ "$IS_COOKER" == "true" ]]; then
            release_type="cooker"
        else
            release_type="main"
        fi
    else
        if [[ "$components_source" == "1" ]]; then
            release_type="cooker"
        else
            release_type="main"
        fi
    fi

    echo "Downloading $release_type components..."
    release_json=$(curl -s "https://api.github.com/repos/RetroDECK/components/releases" | jq "[.[] | select(.name | test(\"$release_type\"))] | sort_by(.published_at) | reverse | .[0]")

    if [[ -z "$release_json" || "$release_json" == "null" ]]; then
        echo "No suitable release found in RetroDECK/components."
        exit 1
    fi

    # Output version info to components/components-version
    release_name=$(echo "$release_json" | jq -r '.name')
    release_tag=$(echo "$release_json" | jq -r '.tag_name')
    release_url=$(echo "$release_json" | jq -r '.html_url')
    {
        echo "name: $release_name"
        echo "tag: $release_tag"
        echo "url: $release_url"
    } > "$COMPONENTS_DIR/components-version"

    echo "$release_json" | jq -r '.assets[] | select(.name | test("source") | not) | "\(.browser_download_url) \(.name)"' | while read -r url name; do
        echo "Downloading $name..."
        curl -L "$url" -o "$COMPONENTS_DIR/$name"
        # Only check SHA256 for .tar.gz files
        if [[ "$name" == *.tar.gz ]]; then
            sha_file="$COMPONENTS_DIR/$name.sha"
            if [[ -f "$sha_file" ]]; then
                expected_sha=$(cat "$sha_file" | awk '{print $1}')
                actual_sha=$(sha256sum "$COMPONENTS_DIR/$name" | awk '{print $1}')
                if [[ "$expected_sha" == "$actual_sha" ]]; then
                    echo "SHA256 checksum for $name matches."
                else
                    echo "WARNING: SHA256 checksum for $name does NOT match!"
                    echo "Expected: $expected_sha"
                    echo "Actual:   $actual_sha"
                    if [[ "$CICD" == "true" ]]; then
                        echo "Checksum mismatch detected in CI/CD mode. Exiting."
                        exit 1
                    else
                        read -rp "Checksum mismatch for $name. Do you want to continue? [y/N] " continue_input
                        continue_input=${continue_input:-N}
                        if [[ ! "$continue_input" =~ ^[Yy]$ ]]; then
                            echo "Aborting due to checksum mismatch."
                            exit 1
                        fi
                    fi
                fi
            else
                echo "No SHA file found for $name, skipping checksum verification."
            fi
        fi
    done
fi
