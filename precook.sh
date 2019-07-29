#!/bin/bash
#
# pre-receive hook to ensure commit message is at least 60 chars and has a ZS id

set -e

zero_commit='0000000000000000000000000000000000000000'
minchars='60'
msg_regex='\bZS[0-9]{5}\b'

while read -r oldrev newrev refname; do

	# Branch or tag got deleted, ignore the push
	[ "$newrev" = "$zero_commit" ] && continue

	# Calculate range for new branch/updated branch
	[ "$oldrev" = "$zero_commit" ] && range="$newrev" || range="$oldrev..$newrev"

	for commit in $(git rev-list "$range" --not --all); do
		msg="$(git log --max-count=1 --format=%B $commit)"
		nchars="$(echo "$msg" |wc -c)"
		error=""
		if [ "$nchars" -lt "$minchars" ]; then
			error+="ERROR:\n"
			error+="ERROR: Commit message has $nchars characters ($minchars required)\n"
			error+="ERROR:\n"
		fi
		if ! echo "$msg" |grep -qE "$msg_regex"; then
			error+="ERROR:\n"
			error+="ERROR: Your commit message lacks a ZS id\n"
		fi
		if [ -n "$error" ]; then
			echo "ERROR:\n"
			echo "ERROR: Your push was rejected because the commit\n"
			echo "ERROR: $commit in ${refname#refs/heads/}\n"
			echo "ERROR: has the following issue(s):\n"
			echo -ne "$error"
			exit 1
		fi
	done

done

exit 0
