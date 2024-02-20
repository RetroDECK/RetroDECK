#!/bin/bash

# Fetch branches from GitHub API excluding "main"
branches=$(curl -s https://api.github.com/repos/XargonWan/RetroDECK/branches | grep '"name":' | awk -F '"' '$4 != "main" {print $4}')
# TODO: logging - Fetching branches from GitHub API

# Create an array to store branch names
branch_array=()

# Loop through each branch and add it to the array
while IFS= read -r branch; do
    branch_array+=("$branch")
done <<< "$branches"
# TODO: logging - Creating array of branch names

# Display branches in a Zenity list dialog
selected_branch=$(zenity --list --title="Select Branch" --column="Branch" --width=1280 --height=800 "${branch_array[@]}")
# TODO: logging - Displaying branches in Zenity list dialog

# Display warning message
if [ $selected_branch ]; then
    zenity --question --text="Are you sure you want to move to \"$selected_branch\" branch?"
    # Output selected branch
    echo "Selected branch: $selected_branch" # TODO: logging - Outputting selected branch
    zenity --info --text="The data will be now downloaded, please stand by."
    # Do stuff here
else
    zenity --warning --text="No branch selected, exiting."
    # TODO: logging
fi
