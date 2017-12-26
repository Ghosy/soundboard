#!/usr/bin/env bash
#
# This program allows the installation of soundboard
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

if [[ $EUID -ne 0 ]]; then
	echo "You must be root to perform this action" 1>&2
	exit 1
else
	# Add to /bin/
	cp "soundboard.sh" "/usr/local/bin/soundboard"

	# Set permissions
	chmod 755 "/usr/local/bin/soundboard"

	# Change owner
	chown root "/usr/local/bin/soundboard"

	# Create manpage dir if it doesn't exist
	mkdir -p "/usr/local/share/man/man1"

	# Install manpage
	cp "doc/soundboard.1" "/usr/local/share/man/man1"
	gzip -q "/usr/local/share/man/man1/soundboard.1"

	# Update manpages database
	mandb -q

	echo "Install success"
fi
