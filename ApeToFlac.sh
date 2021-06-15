#!/bin/bash


############################################################################################
#
#  A SCRIPT TO SPLIT MUSIC ALBUMS (EITHER WITH INPUT .APE OR .FLAC) INTO THE SONGS, IN
#  .FLAC USING A .CUE FILE.
#
#    The script transforms a .ape into .flac using ffmpeg and then splits that .flac
#    into several flacs for each song using a .cue file for the timestamps.
#
#    It can take an array of input directories, and an output directory.
#    If no input directory is specified it uses the working directory, and if no output
#    directory is specified it uses the same as the input directory.
#
############################################################################################


##################
# INITIALIZATION #
##################

# Initialize errors as 0 and we will set it to 1 if an error occurs
errors=0

# Check if ffmpeg is installed
if [[ ! $(which ffmpeg) ]]; then
	echo "[E] Couldn't find ffmpeg. Make sure it is installed."
	errors=1
fi

# Check if flac is installed
if [[ ! $(which flac) ]]; then
	echo "[E] Couldn't find flac. Make sure it is installed."
	errors=1
fi

# Check if shntool is isntalled
if [[ ! $(which shntool) ]]; then
	echo "[E] Couldn't find shntool. Make sure it is installed."
	errors=1
fi

# Add an empty line for readability
echo ""


#############
# FUNCTIONS #
#############

error_exit(){
	echo
	echo "ERRORS WERE FOUND. EXITING"
	echo
	exit 1
}

help_msg(){
	echo
	echo "-i [input_dir0, input_dir1, input_dir2...] The source directory. Defaults to working directory"
	echo "-d [output_dir] The output directory. Defaults to working input directory"
	echo "-h Prints this message"
}


########################
# ARGUMENTS PROCESSING #
########################

while [ ! -z "$1" ]; do
	case "$1" in
		# Source directory
		'-i' | '--input')
			shift
			until [[ "$1" == -* ]] || [[ -z "$1" ]]; do
				if [[ -d "$1"/ ]]; then
					src_dir_arr+=( "$1" )
				else
					echo "[E] Source $1 Not a valid directory"
					errors=1
				fi
				shift
			done
		;;
		# Destination directory
		'-d' | '--destination')
			if [[ -d "$2"/ ]]; then
				out_dir="$2"
			else
				echo "[E] Destination $2 Not a valid directory"
				errors=1
			fi
			shift 2
		;;
		# Help message
		'-h' | '--help')
			help_msg
			exit 0
		;;
		# Undefined argument
		*)
			echo "Undefined argument $1"
			help_msg
			errors=1
		;;
	esac
done

# If any errors have been found exit the program
# Do this here instead of when the error is found to process all the arguments so you can know if there are several
# errors so you don't have to run, find an error, fix it, find a different error, fix it... This way you can fix all
# in one run
if (( $errors != 0 )); then
	error_exit
fi

# If a source directory hasn't been specified use the working directory
if [[ -z $src_dir_arr ]]; then
	src_dir_arr=$(pwd)
fi

# If an output directory hasn't been specified in arguments, set a flag for later
if [[ -z $out_dir ]]; then
	out_dir_defined=0
else
	out_dir_defined=1
fi



########
# MAIN #
########

for src_dir in "${src_dir_arr[@]}"; do
	# Find .ape file
	ape=$(find "$src_dir" -maxdepth 1 -name *.ape)

	# If theres no .ape file try to find a .flac file
	if [[ -z $ape ]]; then
		echo "No .ape file in $src_dir"
		flac=$(find "$src_dir" -maxdepth 1 -name *.flac -print -quit)
		# If theres no .flac file raise an error and exit
		if [[ -z $flac ]]; then
			echo "No .flac file in $src_dir"
			error_exit
		# Else ask if thats a flac file that we want to use for splitting
		else
			echo "Found .flac $flac"
			read -p "Do you want to use $flac for the splitting?[Y/n] " answer
			# Transform answer string to lowercase
			answer_lower=${answer,,}

			# If the answer is no
			if [[ $answer_lower == 'n' ]]; then
				echo
				# Continue with next element in the src_dir_arr
				continue
			# Else the answer isnt one of the defined raise error and exit
			elif [[ $answer_lower != 'y' ]] && [[ ! -z $answer_lower ]]; then
				echo "[E] Not a valid answer"
				error_exit
			fi
		fi

	# Else do this mid step of converting the ape into a flac
	else
		# Create .flac file name to create the mid step later
		flac=${ape/%.*/.flac}

		# convert APE to FLAC:
		ffmpeg -n -i "$ape" "$flac"
		echo ""
	fi

	# Find .cue file
	cue=$(find "$src_dir" -name *.cue -print -quit)
	# If theres no CUE file print error message and continue loop
	if [[ -z "$cue" ]]; then
		echo "[E] No .cue file in $src_dir"
		continue
	fi

	# If a output directory wasn't defined in arguments, use the input directory
	if [ $out_dir_defined -eq 0 ]; then
		out_dir="$src_dir"
	fi

	# Now, split FLAC file
	shnsplit -d "$out_dir" -f "$cue" -t "%n - %t" -o flac "$flac"
done