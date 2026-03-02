#!/bin/bash

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
