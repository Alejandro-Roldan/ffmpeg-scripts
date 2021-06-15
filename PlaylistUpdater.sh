#!/bin/bash


############################################################################################
#
#  A SCRIPT TO UPDATE AND DOWNLOAD NEW PLAYLIST ITEMS AUTOMATICALLY
#
#    The script reads an argument (which is expected to be a directory path) and loops
#    through the directories inside of it, where each one should be a different playlist.
#
#    It works by reading a .url text file inside each directory that specifies the url
#    to the playlist and then uses youtube-dl to download the playlist. Uses an .archive
#    file to know what podcasts episodes have been downloaded already. Converts the output
#    from m4a to mp3 if neccessary.
#
############################################################################################


# Pass argument into directory variable
up_dir="$1"
# Change into needed directory
cd "$up_dir"
# Save active directory into variable (so the var has the full path name)
up_dir="$PWD"


# Loop through each folder inside the directory given in the arguments
for dir in "$up_dir"/*/; do
	# Change directory
	cd "$dir"
	# Read url from .url file
	url=$(cat .url)

	echo "Updating $dir"

	youtube-dl --playlist-reverse --download-archive .archive -o "#%(autonumber)s - %(title)s.%(ext)s" --add-metadata "$url"

	# Convert m4a to mp3 and remove the m4a if succesful
	for f in *.m4a; do
		# Check if $f is a file
		if [[ -f "$f" ]]; then
			ffmpeg -i "$f" -codec:v copy -codec:a libmp3lame -q:a 4 "${f%.m4a}.mp3" && rm "$f"
		fi
	done

	# Go up one directory (used to be used to solve and error with ".", not needed anymore after many code
	# iterations to solve that issue, but commented out to have it in mind and easily usable if any new bugs arise)
	# cd ..
done
