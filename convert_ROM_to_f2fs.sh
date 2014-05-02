#!/bin/bash
#
#####################################
############ Version 0.1 ############
#####################################
#
# This script wants to be a simple solution to patch any ROM
# that writes EXT4 /system partition to F2FS filesystem
#
# Creator: ffigue <arroba> gmail.com
#
#    License:
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Constants
ROMMINSIZE="80000000"
force=0
updater=META-INF/com/google/android/updater-script
tmpfile=/tmp/$updater

# Previous checks
if ! which unzip > /dev/null ; then
    echo "unzip can't be found. Please install it from your repos or add it to PATH. Aborting..."
    exit 1
fi

# Execute getopt on the arguments passed to this program
PARSED_OPTIONS=$(getopt -n "$0"  -o hf --long "help,force"  -- "$@")

# Bad arguments, something has gone wrong with the getopt command.
if [ $? -ne 0 ]; then
    echo "Fatal error parsing arguments."
    exit 1
fi

# With no arguments, script should show usage
if [ "$PARSED_OPTIONS" = " --" ]
then
    PARSED_OPTIONS=' -h --'
fi
 
# A little magic, necessary when using getopt.
eval set -- "$PARSED_OPTIONS";

while true; do
  case "$1" in
    -h|--help|--usage)
        echo "usage $0 [ -h|--help ] [ -f|--force ] your_rom_file.zip"
        exit 0 ;;
    -f|--force)
        echo "==> Disabling ROM file checks"
        force=1
        shift ;;
    --)
        shift
        break ;;
  esac
done

ROMFILE="$1"

if [ -f "$ROMFILE" ]
then
    ROMSIZE=$(stat -c '%s' $ROMFILE)
    if [ "$force" -eq "0" ]
    then
        if [ "$ROMSIZE" -lt "$ROMMINSIZE" ]
        then
            echo "ROM size is less than $(($ROMMINSIZE / 1024 / 1024)) MB. Are you sure that this file is an android ROM? Add force option to bypass this check."
        else
            echo "==> ROM size seems correct !!"
        fi
        # Looking for updater-script
        if unzip -l $ROMFILE $updater > /dev/null
        then
            echo "==> Found updater-script !!"
        fi
    fi
fi

# Uncompressing
if [ -f $tmpfile ]
then
    echo -n "==> Removing old updater-script: "
    rm -vf $tmpfile
fi
unzip $ROMFILE $updater -d /tmp || ( echo "Error writing to /tmp... exiting" && exit 1 )

# Patching entries
sed -e 's/mount(\"ext4\".*by-name\/system.*/run_program(\"\/sbin\/busybox\"\, \"mount\"\, \"\/system\")\;/g' -i $tmpfile
sed -e 's/mount(\"ext4\".*by-name\/userdata.*/run_program(\"\/sbin\/busybox\"\, \"mount\"\, \"\/data\")\;/g' -i $tmpfile
sed -e '/format(\"ext4\"/c\run_program(\"\/sbin\/mkfs.f2fs\"\, \"\/dev\/block\/platform\/msm_sdcc.1\/by-name\/system\")\;' -i $tmpfile

# Adding updater-script again to zip
currentpath=$(pwd)
cd /tmp
zip -r $currentpath/$ROMFILE $updater

echo "==> Done."

# End
