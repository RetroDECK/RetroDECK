#!/bin/bash

# For the file paths to work correctly, call this script with this command from the cloned repo folder root:
# sh automation_tools/pre_build_automation.sh
# Different actions need different information in the task list file
# branch: This changes the placeholder text to the currently-detected GIT branch if an automated build was started from a PR environment.
# hash: Finds the SHA256 hash of a file online and updates the placeholder in the manifest. 
#     Needs the URL of the file, in this line format: hash^PLACEHOLDERTEXT^url
# latestcommit: Finds the most recent commit of a git repo and updated the placeholder in the manifest.
#     Needs the URL of the repo and the branch to find the latest commit from, in this line format: latestcommit^PLACEHOLDERTEXT^url^branch
# latestappimage: Finds the download URL and SHA256 hash of the latest AppImage release from a git repo.
#     Needs the API URL of the repo, in this line format: latestappimage^PLACEHOLDERTEXT^https://api.github.com/repos/<owner-name>/<repo-name>/releases/latest
#     As this command updates two different placeholders (one for the URL, one for the file hash) in the manifest, 
#     the URL that would be used in the above example is "PLACEHOLDERTEXT" and the hash placeholder text would be "HASHPLACEHOLDERTEXT"
#     The "HASH" prefix of the placeholder text is hardcoded in the script
# outside_file: Prints the contents of a file from the build environment (such as the buildid file) and replaces the placeholder text with those contents.
# outside_env_var: Gets the value of an environmental variable from the build environment (the output of "echo $var" from the terminal) and replaces the placeholder text with that value.
# custom_command: Runs a single command explicitly as written in the $URL field of the task list, including variable and command expansion. This should work the same as if you were runnig the command directly from the terminal.
#     This command does not need a PLACEHOLDERTEXT field in the task list, so needs to be in this syntax: custom_command^^$COMMAND
# url: This is used to calculate a dynamic URL and the value to the $caluculated_url environmental variable, for use in other subsequent commands.

rd_manifest=${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml
automation_task_list=${GITHUB_WORKSPACE}/automation_tools/automation_task_list.cfg
current_branch=$(git rev-parse --abbrev-ref HEAD)

# During the PR automated tests instead of the branch name is returned "HEAD", fixing it
if [ $current_branch == "HEAD" ]; then
  echo "Looks like we are on a PR environment, retrieving the branch name from which the PR is raised."
  current_branch=$(echo $GITHUB_REF | sed 's@refs/heads/@@')
  echo "The branch name from which the PR is raised is \"$current_branch\"."
fi

echo "Manifest location: $rd_manifest"
echo "Automation task list location: $automation_task_list"
echo
echo "Task list contents:"
cat "$automation_task_list"
echo

# Update all collected information
while IFS="^" read -r action placeholder url branch
do
  if [[ ! $action == "#"* ]] && [[ ! -z "$action" ]]; then
    case "$action" in

    "branch" )
      echo
      echo "Placeholder text: $placeholder"
      echo "Current branch:" "$current_branch"
      echo
      /bin/sed -i 's^'"$placeholder"'^'"$current_branch"'^g' $rd_manifest
    ;;

    "hash" )
      echo
      echo "Placeholder text: $placeholder"
      calculated_url=$(eval echo "$url")  # in case the url has to be calculated from an expression
      echo "URL to hash: $calculated_url"
      echo
      hash=$(curl -sL "$calculated_url" | sha256sum | cut -d ' ' -f1)
      echo "Hash found: $hash"
      /bin/sed -i 's^'"$placeholder"'^'"$hash"'^' $rd_manifest
    ;;

    "latestcommit" )
      echo
      echo "Placeholder text: $placeholder"
      echo "Repo to get latest commit from: $url branch: $branch"
      echo
      commit=$(git ls-remote "$url" "$branch" | cut -f1)
      echo "Commit found: $commit"
      /bin/sed -i 's^'"$placeholder"'^'"$commit"'^' $rd_manifest
    ;;

    "latestappimage" )
      echo
      echo "Placeholder text: $placeholder"
      echo "Repo to look for AppImage releases: $url"
      echo
      appimageurl=$(curl -s "$url" | grep browser_download_url | grep "\.AppImage\"" | cut -d : -f 2,3 | tr -d \" | sed -n 1p | tr -d ' ')
      echo "AppImage URL found: $appimageurl"
      /bin/sed -i 's^'"$placeholder"'^'"$appimageurl"'^' $rd_manifest
      appimagehash=$(curl -sL "$appimageurl" | sha256sum | cut -d ' ' -f1)
      echo "AppImage hash found: $appimagehash"
      /bin/sed -i 's^'"HASHFOR$placeholder"'^'"$appimagehash"'^' $rd_manifest
    ;;

    "outside_file" )
      if [[ "$url" = \$* ]]; then # If value is a reference to a variable name
        eval url="$url"
      fi
      echo
      echo "Placeholder text: $placeholder"
      echo "Information being injected: $(cat $url)"
      echo
      /bin/sed -i 's^'"$placeholder"'^'"$(cat $url)"'^' $rd_manifest
    ;;

    "outside_env_var" )
      if [[ "$url" = \$* ]]; then # If value is a reference to a variable name
        eval url="$url"
      fi
      echo
      echo "Placeholder text: $placeholder"
      echo "Information being injected: $(echo $url)"
      echo
      /bin/sed -i 's^'"$placeholder"'^'"$(echo $url)"'^' $rd_manifest
    ;;

    "custom_command" )
      echo
      echo "Command to run: $url"
      echo
      eval "$url"
    ;;

    "url" )
      # this is used to calculate a dynamic url
      echo
      echo "Placeholder text: $placeholder"
      calculated_url=$(eval echo "$url")
      echo "Information being injected: $calculated_url"
      echo
      /bin/sed -i 's^'"$placeholder"'^'"$calculated_url"'^' $rd_manifest
    ;;

    esac
  fi
done < "$automation_task_list"
