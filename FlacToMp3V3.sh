#!/bin/bash

############################################################################################
#
#  A FFMPEG SCRIPT TO CONVERT FLAC FILES INTO MP3@320 USING MULTIPLE CORES
#
#    The script uses fd instead of find (since it's much more powerful and executes
#    in parallalel) to find the flac files inside the specified source directory.
#    When it finds a file it then creates a directory with the same name and parent
#    folders in the output directory and after that uses ffmpeg to convert the file into
#    an mp3 at 320 kb/s.
#
#    Once it has converted the flac files it copies the mp3 files that already existed
#    in the source directory into the output directory
#
############################################################################################


# FFMPEG HAS A BUG WHITH THE IMAGE METADATA WHERE IT WILL SOMETIMES MAKE THE FILE 2X BIGGER THAN IT SHOULD
# I SOLVED IT BY REMOVING THE IMAGE ENTIRELY WHEN CONVERTING SO THAT WAY IT NEVER HAPPENS, BUT BECAUSE
# I WANT TO HAVE THE METADATA IMAGES ON THE FILES I HAVE THEN TO REAATACH THE IMAGE AGAIN WITH A PYTHON SCRIPT


##################
# INITIALIZATION #
##################

# Check if fd is installed
if [[ ! $(which fd) ]]; then
	echo "[E] Couldn't find fd. Make sure fd is installed."
fi

# Check if the mutagen python library is installed (to reattach the metadata images)
if [[ $(python -c "import mutagen") ]]; then
	echo "[E] Couldn't find python library mutagen. Make sure mutagen is installed."
fi


# Initialize errors as 0 and we will set it to 1 if an error occurs
errors=0

# Get the script directory
script_dir="$(dirname $0)"

# Add an empty line for readability
echo ""



########################
# ARGUMENTS PROCESSING #
########################

while getopts 's:d:c:h' option; do
	case "${option}" in
		# Source directory
		s)
			if [[ -d ${OPTARG}/ ]]; then
				src_dir=${OPTARG}
			else
				echo "[E] Source ${OPTARG} Not a valid directory"
				errors=1
			fi
		;;
		# Destination directory
		d)
			if [[ -d ${OPTARG}/ ]]; then
				out_dir=${OPTARG}
			else
				echo "[E] Destination ${OPTARG} Not a valid directory"
				errors=1
			fi
		;;
		# Number of cores
		c) 
			if (( ${OPTARG} <= $(nproc) )); then
				cores=${OPTARG}
			else
				echo "[E] Specified Number of cores (${OPTARG}) greater than Number of cores available ($(nproc))"
				errors=1
			fi
		;;
		# Help
		h)
			echo "-s [source] The source directory. Defaults to working directory"
			echo "-d [destination] The output directory. Defaults to working directory"
			echo "-c [number_of_cores] Optional. The number of cores to use. Defaults to MAX"
		;;
		# Unspecified argument
		*) errors=1;;
	esac
done

# If any errors have been found exit the program
# Do this here instead of when the error is found to process all the arguments so you can know if there are several
# errors so you don't have to run, find an error, fix it, find a different error, fix it... This way you can fix all
# in one run
if (( $errors != 0 )); then
	echo "Errors were found. Exiting"
	echo ""
	exit 1
fi

# If a source directory hasn't been specified use the working directory
if [[ -z $src_dir ]]; then
	src_dir=$(pwd)
fi

# If an output directory hasn't been specified use the wroking directory
if [[ -z $out_dir ]]; then
	out_dir=$(pwd)
fi

# If cores hasn't been specified use maximum number available
if [[ -z $cores ]]; then
	cores=$(nproc)
fi


########
# MAIN #
########

# Using fd spans multi-threaded processes while find doesn't

# Use fd in the source directory (--search-path) to find all files (-t)
# with flac extension (-e), for each result execute (-x) a bash.
# The bash call is needed to be able to do string substitutions over
# the finded paths (since fd uses {} to call the paths inside the -x
# using ${} gives substitution errors) so we call bash and pass it the
# arguments we want that we can then call with $n.
# Inside the bash we create the output directories,
# then ffmpeg the flac to mp3 @ 320kb/s (-b),without cover image (-map)
# (because sometimes it gives encoding errors and makes the files 2x
# bigger) only if its a newer file (-n),
# then if only if the ffmpeg succeeded, we find the cover image for
# that song using the song path minus the filename and removing the possible
# '/Disc*' folder (if present) and only searching in that very folder
# (-maxdepth 1) and pipe the output to my AutoImageCover.py that
# sets the metadata image via xargs with % as the selected char to replace
# the argument (-I) and specifying that the variable must be used as a literal
# string (-0) (which also makes it have a \n at the end, so that must be
# removed in the python script).

fd -j $cores -t f -e flac --search-path "$src_dir" -x bash -c 'mkdir -p -m 777 "${1/#$3/$4}";
	ffmpeg -n -i "$0" -map 0:a -b:a 320k "${2/#$3/$4}.mp3" && {
		find "${1%\/Disc*}" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) |
		xargs -0 -I % python "$5/AutoImageCover.py" "${2/#$3/$4}.mp3" %
	}' {} {//} {.} "$src_dir" "$out_dir" "$script_dir"


# Use fd to find the files (-t) with mp3 extension (-e) and bash each result
# (same reason as before)
# Do one first path string substitution for the directory prefix with an
# echo so ge can then use the result in the next command  and output it to
# /dev/null so it doesn't print to terminal, and then another string substitution
# to remove the ' [mp3]',
# finally create the directory and its parents (-p) with mode 777 (-m),
# then copy the song to that directory only if its newer (-u) with verbosity (-v)

fd -t f -e mp3 --search-path "$src_dir" -x bash -c 'echo "${1/#$2/$3}" > /dev/null;
	mkdir -p -m 777 "${_/ \[mp3]/}";
	cp -uv "$0" "$_"' {} {//} "$src_dir" "$out_dir"


# Add empty line for readability
echo ""


# $SECONDS is a builtin variable that stores the seconds the script has
# been running
# Use that to print the real time the script took
# times prints the user and sys time
# exit call
ELAPSED="Real: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
ret=$?; echo "$ELAPSED"; times; echo ""; exit "$ret"

