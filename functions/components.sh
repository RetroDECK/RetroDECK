#!/bin/bash

# Component-parsing-related variables
component_manifest_cache=""

find_component_files() {
  # Find files of a given name across all component directories, with external components taking precedence over internal ones when both exist.
  # Returns a newline-separated list of file paths where the requested file was found.
  # USAGE: find_component_files "$filename" ["$component_name"]

  local filename="$1"
  local component="${2:-all}"
  local -a result_files=()

  if [[ "$component" == "all" ]]; then
    local -A seen_components

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      seen_components["$(basename "$(dirname "$file")")"]=1
      result_files+=("$file")
    done < <(find "$rd_external_components" -maxdepth 2 -mindepth 2 -type f -name "$filename" 2>/dev/null)

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      local component_name
      component_name=$(basename "$(dirname "$file")")
      if [[ -z "${seen_components[$component_name]+x}" ]]; then
        result_files+=("$file")
      fi
    done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "$filename" 2>/dev/null)
  else
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      result_files+=("$file")
    done < <(find "$rd_external_components/$component" -maxdepth 1 -mindepth 1 -type f -name "$filename" 2>/dev/null)

    if [[ ${#result_files[@]} -eq 0 ]]; then
      while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        result_files+=("$file")
      done < <(find "$rd_components/$component" -maxdepth 1 -mindepth 1 -type f -name "$filename" 2>/dev/null)
    fi
  fi

  if [[ ${#result_files[@]} -gt 0 ]]; then
    printf '%s\n' "${result_files[@]}"
  fi
}

build_component_manifest_cache() {
  # Build the component manifest cache from all installed component manifests.
  # Should be called once during application startup. Cache remains valid for the session.
  # USAGE: build_component_manifest_cache

  local -a manifest_files=()
  while IFS= read -r manifest_file; do
    [[ -n "$manifest_file" ]] && manifest_files+=("$manifest_file")
  done < <(find_component_files "component_manifest.json")

  if [[ ${#manifest_files[@]} -eq 0 ]]; then
    component_manifest_cache='[]'
    return
  fi

  component_manifest_cache=$(
    for manifest_file in "${manifest_files[@]}"; do
      jq -c --arg path "$(dirname "$manifest_file")" \
        '{component_path: $path, manifest: .}' "$manifest_file"
    done | jq -s '.'
  )
}

get_component_manifest_cache() {
  # Return the cached component manifest data. Requires build_component_manifest_cache to have been called.
  # USAGE: get_component_manifest_cache

  if [[ -z "$component_manifest_cache" ]]; then
    log e "Component manifest cache is empty. Was build_component_manifest_cache called?"
    return 1
  fi

  echo "$component_manifest_cache"
}

get_all_helper_files() {
  # Gather all helper file information from all component manifests, including the source path for each file.
  # Returns a JSON array of helper file objects with filename, location, and source_path.
  # USAGE: get_all_helper_files

  get_component_manifest_cache | jq '
    [.[] | .component_path as $component_path |
     .manifest | .. | objects | select(has("helper_files")) |
     .helper_files | to_entries[].value |
     . + {source_path: ($component_path + "/rd_assets/helper_files")}]
  '
}

deploy_helper_files() {
  # Distribute helper documentation files throughout the filesystem according to component manifest configurations.
  # USAGE: deploy_helper_files

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    read -r file dest source_path < <(jq -r '[.filename, .location, .source_path] | @tsv' <<< "$entry")
    dest=$(envsubst <<< "$dest")

    if [[ -z "$file" || -z "$dest" ]]; then
      continue
    fi

    if [[ ! -f "$source_path/$file" ]]; then
      log d "Helper file $file not found at $source_path, skipping..."
      continue
    fi

    if [[ -d "$dest" ]]; then
      log d "Copying helper file $file from $source_path to $dest"
      cp -f "$source_path/$file" "$dest/$file"
    else
      log d "Helper file location $dest does not exist, component may not be installed. Skipping..."
    fi
  done < <(get_all_helper_files | jq -c '.[]')
}

get_all_compression_targets() {
  # Gather all compression target information from component manifests.
  # Returns a JSON object keyed by format with target_systems and optional compressable_extensions.
  # USAGE: get_all_compression_targets

  get_component_manifest_cache | jq '
    reduce (.[] | .manifest | .. | objects | select(has("compression")) | .compression | to_entries[]) as $entry (
      {};
      .[$entry.key] = {
        target_systems: ((.[$entry.key].target_systems // []) + ($entry.value.target_systems // []) | unique)
      }
      | if $entry.value.compressable_extensions then
          .[$entry.key].compressable_extensions = ((.[$entry.key].compressable_extensions // []) + $entry.value.compressable_extensions | unique)
        else . end
    )
  '
}

build_compression_lookups() {
  # Build associative array lookups from compression target data for fast per-file matching.
  # Should be called once before batch operations like api_get_compressible_games.
  # USAGE: build_compression_lookups

  local compression_targets
  compression_targets=$(get_all_compression_targets)

  _compression_system_format=()
  _compression_ext_restrictions=()
  _compression_allowed_extensions=()

  # Build system -> format lookup
  while IFS=$'\t' read -r format system; do
    _compression_system_format["$system"]="$format"
  done < <(jq -r '
    to_entries[] | .key as $fmt |
    .value.target_systems[] |
    [$fmt, .] | @tsv
  ' <<< "$compression_targets")

  # Build extension restriction flags and allowed extensions per format
  while IFS=$'\t' read -r format extension; do
    _compression_ext_restrictions["$format"]=1
    _compression_allowed_extensions["${format}:${extension}"]=1
  done < <(jq -r '
    to_entries[]
    | select(.value.compressable_extensions)
    | .key as $fmt
    | .value.compressable_extensions[]
    | [$fmt, .] | @tsv
  ' <<< "$compression_targets")
}

find_compatible_compression_format() {
  # Determine what compression format, if any, a file and its system are compatible with.
  # Requires build_compression_lookups to have been called.
  # Returns the format name or "none".
  # USAGE: find_compatible_compression_format "$file"

  local file="$1"
  local normalized_filename=$(echo "$file" | tr '[:upper:]' '[:lower:]')
  local file_extension=".${normalized_filename##*.}"
  local system=$(echo "$file" | grep -oE "$roms_path/[^/]+" | grep -oE "[^/]+$")

  # Look up format for this system
  local format="${_compression_system_format[$system]:-}"
  if [[ -z "$format" ]]; then
    echo "none"
    return
  fi

  # Check extension restrictions if the format has them
  if [[ -n "${_compression_ext_restrictions[$format]+x}" ]]; then
    if [[ -z "${_compression_allowed_extensions[${format}:${file_extension}]+x}" ]]; then
      echo "none"
      return
    fi
  fi

  # Run format-specific validation
  local validator="_validate_for_compression::${format}"
  if declare -F "$validator" > /dev/null; then
    if [[ $("$validator" "$file") ]]; then
      echo "$format"
    else
      echo "none"
    fi
  else
    log e "No validation handler found for format: $format"
    echo "none"
  fi
}
