#!/bin/bash
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
short=cf:ho
long=cancel,file:,help,mplayer-override,overlap,volume:

# Create lockfile if none exists
cat /dev/null >> $lf

print_usage() {
	echo -e "Usage: soundboard [OPTION]..." 
	echo -e "  -c, --cancel              allows the selected file to be stopped if playing"
	echo -e "  -f, --file                file to be played"
	echo -e "  -h, --help                show this help message"
	echo -e "      --mplayer-override    override use of mpv with mplayer"
	echo -e "  -o, --overlap             allows sound to be played multiple times at once"
	echo -e "      --volume=VOLUME       set the level for clip's volume(0-100)"
	exit 0
}

check_depends() {
	if type mpv &>/dev/null; then
		playcmd="mpv"
	elif type mplayer &>/dev/null; then
		playcmd="mplayer"
	else
		echo "Neither mpv or mplayer are not installed. Please install either mpv or mplayer."
		exit 1
	fi
}

main() {
	check_depends

	getopt --test > /dev/null
	if [[ $? != 4 ]]; then
		echo "getopt is not functioning as anticipated"
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
			-c|--cancel)
				cancel=true
				;;
			-f|--file)
				filename="$2"
				shift
				;;
			-h|--help)
				# Print help/usage
				print_usage
				;;
			--mplayer-override)
				if ! type mplayer &>/dev/null; then
					echo -e "mplayer must be installed for --mplayer-override"
					exit 1
				else
					playcmd="mplayer"
				fi
				
				;;
			-o|--overlap)
				overlap=true
				;;
			--volume)
				if [[ ! $2 =~ ^[0-9]+$ ]] || [ ! "$2" -ge 0 ] || [ ! "$2" -le 100 ]; then
					echo -e "\"$2\" is not a valid value for volume"
					echo -e "volume must be within 0-100"
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
				echo "Argument not properly handled"
				exit 64
				;;
		esac
		shift
	done

	# Checks to see if file is specified and if readable
	if [ -r "$filename" ] && [ "$filename" != "" ]; then

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
			($playcmd --no-terminal --volume="$volume" "$filename") &
			echo "$filename $!" >> $lf

			# Wait for child to die and remove entry from lock file
			wait $! 2> /dev/null
			# Not portable requires GNU sed
			# Using # delimiter to avoid issues with file path
			sed -i "\\#$filename $!#d" $lf
		# If file is being played and should be canceled
		elif grep -Fq "$filename" $lf && ($cancel); then
			pid=$(grep "$filename" $lf | awk -F " " '{print $2}')
			kill -9 "$pid"
		fi
	else
		# Doesn't reflect not readable should be rewritten
		echo -e "File not found" >&2
	fi
}

main "$@"
