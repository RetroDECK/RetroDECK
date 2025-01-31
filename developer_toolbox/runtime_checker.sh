#!/bin/bash

# TODO: finish me

# Set the organization name
ORG="RetroDECK"

# Get all non-archived repositories of the organization
repos=$(curl -s "https://api.github.com/orgs/$ORG/repos?per_page=100" | jq -r '.[] | select(has("archived") and .archived == false) | .name')

# Iterate over each repository
for repo in $repos; do
  echo "Checking repository: $repo"
  
  # Get the files in the root of the repository
  files=$(curl -s "https://api.github.com/repos/$ORG/$repo/contents" | jq -r '.[] | select(.type == "file" and (.path | index("/") == null)) | .name')
  
  # Check for .yml, .yaml, and .json files
  for ext in yml yaml json; do
    file=$(echo "$files" | grep -E "\.$ext$")
    if [ -n "$file" ]; then
      # Download the file content
      content=$(curl -s "https://raw.githubusercontent.com/$ORG/$repo/main/$file")
      
      # Check if it contains "runtime"
      if echo "$content" | grep -q "runtime"; then
        echo "Found in $file"
        app_id=$(echo "$content" | grep "app-id" | awk '{print $2}')
        runtime=$(echo "$content" | grep "runtime" | awk '{print $2}')
        runtime-version=$(echo "$content" | grep "runtime-version" | awk '{print $2}')
        sdk=$(echo "$content" | grep "sdk" | awk '{print $2}')
        
        echo "Repository: $repo"
        echo "File: $file"
        echo "app-id: $app_id"
        echo "runtime: $runtime"
        echo "runtime-version: $runtime_version"
        echo "sdk: $sdk"
        echo "-------------------------"
        break
      fi
    fi
  done
done