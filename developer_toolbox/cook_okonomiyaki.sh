#!/bin/bash

# List of branches to pull and merge
branches=(
  "cooker"
  "feat/shadps4"
  "feat/godot"
)

# Pull Request ID to merge (add your PR IDs here)
pull_requests=(
  983 # Cohee1207:Add megadrive to ZIP compression targets
  981 # Cohee1207:bug/fix-ps2-createcd
  974 # Cohee1207:feat/ppsspp-cheevos
  863 # kageurufu:primehack-steamdeck-fix
  842 # feat/game-downloader
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
    if ! git merge origin/$branch; then
      echo "Merge conflict detected while merging $branch!"
      echo "Please resolve the conflict, then run 'git merge --continue' to finish the merge."
      exit 1  # Exit the script due to conflict
    fi
  done

  # Iterate through the list of pull requests
  for pr_id in "${pull_requests[@]}"; do
    echo "Fetching PR #$pr_id..."
    git fetch origin pull/$pr_id/head:pr-$pr_id
    
    echo "Merging PR #$pr_id into $current_branch..."
    if ! git merge pr-$pr_id; then
      echo "Merge conflict detected while merging PR #$pr_id!"
      echo "Please resolve the conflict, then run 'git merge --continue' to finish the merge."
      exit 1  # Exit the script due to conflict
    fi
  done

else
  echo "Current branch is not an okonomiyaki branch, quitting."
  exit 1
fi