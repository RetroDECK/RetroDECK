#!/bin/bash

# List of branches to pull and merge
branches=(
  "cooker"
  "feat/shadps4"
  "feat/PortMaster"
  "feat/steam-rom-manager"
)

# Get the current branch name
current_branch=$(git branch --show-current)

# Check if the current branch contains 'feat/' and 'okonomiyaki'
if [[ $current_branch == feat/* && $current_branch == *okonomiyaki* ]]; then
  echo "Current branch is $current_branch, proceeding with fetch, pull, and merge."

  # Iterate through the list of branches
  for branch in "${branches[@]}"; do
    echo "Fetching $branch..."
    git fetch origin $branch
    
    echo "Pulling $branch..."
    git pull origin $branch
    
    echo "Merging $branch into $current_branch..."
    git merge origin/$branch
  done
else
  echo "Current branch is not an okonomiyaki branch, quitting."
  exit 1
fi
