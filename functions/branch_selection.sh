#!/bin/bash

# Fetch branches from GitHub API
branches=$(curl -s https://api.github.com/repos/XargonWan/RetroDECK/branches | grep '"name":' | awk -F '"' '{print $4}')
# TODO logger

# Create an array to store branch names
branch_array=()

# Loop through each branch and add it to the array
while IFS= read -r branch; do
    branch_array+=("$branch")
done <<< "$branches"

# Display branches in a Zenity list dialog
selected_branch=$(zenity --list --title="Select Branch" --column="Branch" "${branch_array[@]}")
# TODO: logger

# Output selected branch
echo "Selected branch: $selected_branch" # TODO: logger