#!/bin/bash

# Lock file
lf=/tmp/sbLockFile

overlap=false
cancel=false
# Getopt
short=cf:ho
long=cancel,file:,help,overlap

# Create lockfile if none exists
cat /dev/null >> $lf

print_usage() {
	echo -e "Usage: soundboard [OPTION]..." 
	echo -e "  -c, --cancel     allows the selected file to be stoped if playing"
	echo -e "  -f, --file       file to be played"
	echo -e "  -h, --help       show this help message"
	echo -e "  -o, --overlap    allows sound to be played multiple times at once"
	exit 0
}

getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "getopt is not functioning as anticipated"
	exit 1
fi

parsed=`getopt --options $short --longoptions $long --name "$0" -- "$@"`
if [[ $? != 0 ]]; then
	# Getopt not getting correcty aruments
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
		-o|--overlap)
			overlap=true
			;;
		--)
			shift
			break
			;;
		*)
			# Unknown option
			echo "Arguement not properly handled"
			exit 64
			;;
	esac
	shift
done

#amidi -p hw:6,0,0 --send-hex '90 00 3c'
#amidi -p hw:6,0,0 --send-hex '90 00 00'

# Checks to see if file is specified and if readable
if [ -r $filename ] && [ "$filename" != "" ]; then
	# Plays if filename not in lockfile or if overlap is enabled
	notinlock=! 
	if ! grep -Fq "$filename" $lf || ($overlap); then
		echo "$filename $$" >> $lf
		# TODO: Why is this surrounded by parens
		(aplay -q $filename)
		# Not portable requires GNU sed
		# Using # delimiter to avoid issues with file path
		sed -i "\#$filename $$#d" $lf
	elif grep -Fq "$filename" $lf && ($cancel); then
		pid=$(grep "$filename" $lf | awk -F " " '{print $2}')
		kill -9 $pid
		sed -i "\#$filename $pid#d" $lf
	fi
else
	# Doesn't reflect not readable should be rewritten
	echo -e "File not found" >&2
fi
