#!/sbin/sh
#
# This script wants to be a simple solution to generate a fstab for Mako
# 
# Script detects partitions format and generate the correct fstab entry.
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
# Sources:
# https://android.googlesource.com/device/lge/mako/+/master/fstab.mako
# http://forum.xda-developers.com/showpost.php?p=51659075

fstabfile="/tmp/ramdisk/fstab.mako"

# Start fstab generator
# Detecting filesystems
if ! grep -q /system /etc/mtab ; then
    mount /system
fi
FORMAT_SYS=$(grep /system /etc/mtab | awk '{print $3}')
umount /system

if ! grep -q /data /etc/mtab ; then
    mount /dev/block/platform/msm_sdcc.1/by-name/userdata /data
fi
FORMAT_DAT=$(grep /data /etc/mtab | awk '{print $3}')

if ! grep -q /cache /etc/mtab ; then
    mount /dev/block/platform/msm_sdcc.1/by-name/cache /cache
fi
FORMAT_CAC=$(grep /cache /etc/mtab | awk '{print $3}')

# Writting /system
echo "Writting /system to $FORMAT_SYS"
if [ "$FORMAT_SYS" = "f2fs" ]; then
    sed -e '/by-name\/system/c\\/dev\/block\/platform\/msm_sdcc.1\/by-name\/system       \/system         f2fs    ro,noatime,nosuid,nodev,discard,nodiratime,inline_xattr,errors=recover    wait' -i $fstabfile
elif [ "$FORMAT_SYS" = "ext4" ]; then
    sed -e '/by-name\/system/c\\/dev\/block\/platform\/msm_sdcc.1\/by-name\/system       \/system         ext4    ro,noatime,noauto_da_alloc,barrier=0,data=writeback                                           wait' -i $fstabfile
fi

# Writting /cache
echo "Writting /cache to $FORMAT_CAC"
if [ "$FORMAT_CAC" = "f2fs" ]; then
    sed -e '/by-name\/cache/c\\/dev\/block\/platform\/msm_sdcc.1\/by-name\/cache        \/cache          f2fs    noatime,nosuid,nodev,discard,nodiratime,inline_xattr,inline_data,errors=recover       wait,check' -i $fstabfile
elif [ "$FORMAT_CAC" = "ext4" ]; then
    sed -e '/by-name\/cache/c\\/dev\/block\/platform\/msm_sdcc.1\/by-name\/cache        \/cache          ext4    noatime,nosuid,nodev,nomblk_io_submit,errors=panic,noauto_da_alloc,barrier=0,data=writeback    wait,check' -i $fstabfile
fi

# Writting /data
echo "Writting /data to $FORMAT_DAT"
if [ "$FORMAT_DAT" = "f2fs" ]; then
    sed -e '/by-name\/userdata/c\\/dev\/block\/platform\/msm_sdcc.1\/by-name\/userdata     \/data           f2fs    noatime,nosuid,nodev,discard,nodiratime,inline_xattr,inline_data,errors=recover       wait,check,encryptable=/dev/block/platform/msm_sdcc.1/by-name/metadata' -i $fstabfile
elif [ "$FORMAT_DAT" = "ext4" ]; then
    sed -e '/by-name\/userdata/c\\/dev\/block\/platform\/msm_sdcc.1\/by-name\/userdata     \/data           ext4    noatime,nosuid,nodev,nomblk_io_submit,errors=panic,noauto_da_alloc,barrier=0    wait,check,encryptable=/dev/block/platform/msm_sdcc.1/by-name/metadata' -i $fstabfile
fi

# End
