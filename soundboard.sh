#!/usr/bin/env bash
#
# This program allows the playing of audio files in a way similar to a real soundboard
# Copyright (c) 2017 Zachary Matthews.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# Lock file
lf=/tmp/sbLockFile

overlap=false
cancel=false
playcmd=""
volume=100
# Getopt
short=acho
long=all,cancel,help,mplayer-override,overlap,volume:,version

# Create lockfile if none exists
cat /dev/null >> $lf

print_usage() {
	echo "Usage: soundboard [OPTION]... FILE" 
	echo "  -a, --all                 cancels all currently playing sounds"
	echo "  -c, --cancel              allows the file, from -f, to be stopped if playing"
	echo "  -h, --help                show this help message"
	echo "      --mplayer-override    override use of mpv with mplayer"
	echo "  -o, --overlap             allows sound to be played multiple times at once"
	echo "      --version             show the version information for soundboard"
	echo "      --volume=VOLUME       set the level for clip's volume(0-100)"
	exit 0
}

print_version() {
	echo "soundboard, version 0.1"
	echo "Copyright (C) 2015-2018 Zachary Matthews"
	echo "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>"
	echo ""
	echo "This is free software; you are free to change and redistribute it."
	echo "There is NO WARRANTY, to the extent permitted by law."
	exit 0
}

check_depends() {
	if type mpv &>/dev/null; then
		playcmd="mpv"
	elif type mplayer &>/dev/null; then
		playcmd="mplayer"
	else
		echo "Neither mpv or mplayer are not installed. Please install either mpv or mplayer." >&2
		exit 1
	fi
}

# Kills file name provided, if in lock file
cancel() {
	regex=" ([0-9]+)$"
	if [[ $(grep "$1" $lf) =~ $regex ]]; then
		kill -9 "${BASH_REMATCH[1]}"
	fi
}

cancel_all() {
	while read -r line; do
		cancel "$line"
	done < $lf
	exit 0
}

main() {
	check_depends

	getopt --test > /dev/null
	if [[ $? != 4 ]]; then
		echo "getopt is not functioning as anticipated" >&2
		exit 1
	fi

	parsed=$(getopt --options $short --longoptions $long --name "$0" -- "$@")
	if [[ $? != 0 ]]; then
		# Getopt not getting arguments correctly
		exit 2
	fi

	eval set -- "$parsed"

	while true; do
		case $1 in
			-a|--all)
				cancel_all
				;;
			-c|--cancel)
				cancel=true
				;;
			-h|--help)
				# Print help/usage
				print_usage
				;;
			--mplayer-override)
				# Ensure mplayer is in fact installed
				if ! type mplayer &>/dev/null; then
					echo "mplayer must be installed for --mplayer-override" >&2
					exit 1
				else
					playcmd="mplayer"
				fi
				
				;;
			-o|--overlap)
				overlap=true
				;;
			--version)
				print_version
				;;
			--volume)
				# Check volume recieved is a valid number
				if [[ ! $2 =~ ^[0-9]+$ ]] || [ ! "$2" -ge 0 ] || [ ! "$2" -le 100 ]; then
					echo "\"$2\" is not a valid value for volume" >&2
					echo "volume must be within 0-100" >&2
					exit 1
				fi
				volume="$2"
				shift
				;;
			--)
				shift
				break
				;;
			*)
				# Unknown option
				echo "Argument not properly handled" >&2
				exit 64
				;;
		esac
		shift
	done

	# Ensure a file is specified
	if [ "$*" == "" ]; then
		echo "A file must be specified" >&2
		exit 1;
	fi

	# Loop through listed files
	for filename in "$@"; do
		# Checks to see if file is specified and if readable
		if [ -r "$filename" ]; then

			# Check for bad entries in lock file
			pid=$(grep "$filename" $lf | awk -F " " '{print $2}')
			if [[ $pid =~ ^[0-9]+$ ]] && ! kill -0 "$pid"; then
				# Not portable requires GNU sed
				# Using # delimiter to avoid issues with file path
				sed -i "\\#$filename $pid#d" $lf
			fi

			# Plays if filename not in lockfile or if overlap is enabled
			if ! grep -Fq "$filename" $lf || ($overlap); then
				# create subshell to play sound
				($playcmd --no-terminal --no-video --volume="$volume" "$filename") &
				echo "$filename $!" >> $lf

				# Wait for child to die and remove entry from lock file
				wait $! 2> /dev/null
				# Not portable requires GNU sed
				# Using # delimiter to avoid issues with file path
				sed -i "\\#$filename $!#d" $lf
				# If file is being played and should be canceled
			elif grep -Fq "$filename" $lf && ($cancel); then
				cancel "$filename"
			fi
		else
			# Doesn't reflect not readable should be rewritten
			echo "File not found" >&2
		fi
	done
}

main "$@"
