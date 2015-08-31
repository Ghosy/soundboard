#!/bin/bash

# Lock file
lf=/tmp/sbLockFile

overlap=0

# Create lockfile if none exists
cat /dev/null >> $lf

print_usage() {
	echo -e "Usage: soundboard [OPTION]..." 
	echo -e "  -h, --help       show this help message"
	echo -e "  -f, --file       file to be played"
	echo -e "  -o, --overlap    allows sound to be played multiple times at once"
	exit 1
}

while [ "$1" ]; do
	case $1 in
	-h | --help)
		# Print help/usage
		print_usage
		;;
	-f | --file)
		filename="$2"
		shift
		;;
	-o | --overlap)
		overlap=1
		;;
	--*)
		# Invalid long option
		echo "Invalid option: $1" >&2
		exit 1
		;;
	-?)
		# Invalid short option
		echo "Invalid option: $1" >&2
		exit 1
		;;
	esac
	shift
done

#amidi -p hw:6,0,0 --send-hex '90 00 3c'
#amidi -p hw:6,0,0 --send-hex '90 00 00'

# Checks to see if file is specified and if readable
if [ -r $filename ] && [ "$filename" != "" ]; then
	# Plays if filename not in lockfile or if overlap is enabled
	if ! grep -Fq "$filename" $lf || [ $overlap == 1 ]; then
		echo "$filename $$" >> $lf
		play -q $filename &> /dev/null
		# Not portable requires GNU sed
		# Using # delimiter to avoid issues with file path
		sed -i "#$filename $$#d" $lf
	fi
else
	# Doesn't reflect not readable should be rewritten
	echo -e "File not found" >&2
fi
