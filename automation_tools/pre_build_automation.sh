#!/bin/bash

# For the file paths to work correctly, call this script with this command from the cloned repo folder root:
# sh automation_tools/pre_build_automation.sh
# Different actions need different information in the task list file
# hash: Finds the SHA256 hash of a file online and updates the placeholder in the manifest. 
#     Needs the URL of the file, in this line format: hash^PLACEHOLDERTEXT^url
# latestcommit: Finds the most recent commit of a git repo and updated the placeholder in the manifest.
#     Needs the URL of the repo and the branch to find the latest commit from, in this line format: latestcommit^PLACEHOLDERTEXT^url^branch
# latestappimage: Finds the download URL and SHA256 hash of the latest AppImage release from a git repo
#     Needs the API URL of the repo, in this line format: latestappimage^PLACEHOLDERTEXT^https://api.github.com/repos/<owner-name>/<repo-name>/releases/latest
#     As this command updates two different placeholders (one for the URL, one for the file hash) in the manifest, 
#     the URL that would be used in the above example is "PLACEHOLDERTEXT" and the hash placeholder text would be "HASHPLACEHOLDERTEXT"
#     The "HASH" prefix of the placeholder text is hardcoded in the script

# Heredocs are indented with TABS not SPACES - if you use spaces they won't work while indented

main() {
    rd_manifest="${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml"
    automation_task_list="${GITHUB_WORKSPACE}/automation_tools/automation_task_list.cfg"
    current_branch="$(git rev-parse --abbrev-ref HEAD)"

    cat <<-_EOF_
	Manifest location: ${rd_manifest}
	Automation task list location: ${automation_task_list}

	Task list contents:
	$(cat "${automation_task_list}")

	_EOF_

    # Update all collected information
    while IFS="^" read -r action placeholder url branch; do
        if [[ ! $action == "#"* ]] && [[ ! -z "$action" ]]; then
            case $action in
                "branch")
                    cat <<-_EOF_

					Placeholder text: ${placeholder}
					Current branch:   ${current_branch}

					_EOF_
                    /bin/sed -i 's^'"$placeholder"'^'"$current_branch"'^g' $rd_manifest
                    ;;
                "hash")
                    cat <<-_EOF_
					Placeholder text: ${placeholder}
					URL to hash: ${url}

					Hash found: $(curl -sL "$url" | sha256sum | cut -d ' ' -f1)
					_EOF_
                    /bin/sed -i 's^'"$placeholder"'^'"$hash"'^' $rd_manifest
                    ;;
                "latestcommit")
                    cat <<-_EOF_
					Placeholder text: ${placeholder}
					Repo to get latest commit from: ${url} branch: ${branch}

					Commit found: =$(git ls-remote "$url" "$branch" | cut -f1)
					_EOF_
                    /bin/sed -i 's^'"$placeholder"'^'"$commit"'^' $rd_manifest
                    ;;
                "latestappimage")
                    cat <<-_EOF_

					Placeholder text: ${placeholder}
					Repo to look for AppImage releases: ${url}

					AppImage URL found: $(curl -s "$url" | grep browser_download_url | grep "\.AppImage\"" | cut -d : -f 2,3 | tr -d \" | sed -n 1p | tr -d ' ')"
					_EOF_
                    /bin/sed -i 's^'"$placeholder"'^'"$appimageurl"'^' $rd_manifest
                    cat <<-_EOF_
					AppImage hash found: $(curl -sL "$appimageurl" | sha256sum | cut -d ' ' -f1)
					_EOF_
                    /bin/sed -i 's^'"HASHFOR$placeholder"'^'"$appimagehash"'^' $rd_manifest
                    ;;
                "outside_info")
                    if [[ "$url" = \$* ]]; then # If value is a reference to a variable name
                        eval url="$url"
                    fi
                    cat <<-_EOF_

					Placeholder text: ${placeholder}
					Information being injected: $(cat ${url})

					_EOF_
                    /bin/sed -i 's^'"$placeholder"'^'"$(cat $url)"'^' $rd_manifest
                    ;;
            esac
        fi
    done < "$automation_task_list"
}
main "$@
