#!/bin/sh
#
#     SUSE system startup script for MD RAID autostart
#     Copyright (C) 1995--2005  Kurt Garloff, SUSE / Novell Inc.
#     Copyright (C) 2006  Marian Jancar, SUSE / Novell Inc.
#          
#     This library is free software; you can redistribute it and/or modify it
#     under the terms of the GNU Lesser General Public License as published by
#     the Free Software Foundation; either version 2.1 of the License, or (at
#     your option) any later version.
#			      
#     This library is distributed in the hope that it will be useful, but
#     WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#     Lesser General Public License for more details.
#      
#     You should have received a copy of the GNU Lesser General Public
#     License along with this program; if not, write to the Free Software
#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#     02110-1301 USA.
#
### BEGIN INIT INFO
# Provides:          boot.md
# Required-Start:    boot.udev boot.rootfsck
# Required-Stop:     $null
# Should-Start: boot.scsidev boot.multipath udev-trigger
# Should-Stop: boot.scsidev boot.multipath
# Default-Start:     B
# Default-Stop:
# Short-Description: Multiple Device RAID
# Description:       Start MD RAID
#	RAID devices are virtual devices created from two or more real block devices.
#	This allows multiple devices (typically disk drives or partitions there-of)
#	to be combined into a single device to hold (for example) a single filesystem.
#	Some RAID levels include redundancy and so can survive some degree of device failure.
### END INIT INFO

# Source LSB init functions
# providing start_daemon, killproc, pidofproc, 
# log_success_msg, log_failure_msg and log_warning_msg.
# This is currently not used by UnitedLinux based distributions and
# not needed for init scripts for UnitedLinux only. If it is used,
# the functions from rc.status should not be sourced or used.
#. /lib/lsb/init-functions

# Shell functions sourced from /etc/rc.status:
#      rc_check         check and set local and overall rc status
#      rc_status        check and set local and overall rc status
#      rc_status -v     be verbose in local rc status and clear it afterwards
#      rc_status -v -r  ditto and clear both the local and overall rc status
#      rc_status -s     display "skipped" and exit with status 3
#      rc_status -u     display "unused" and exit with status 3
#      rc_failed        set local and overall rc status to failed
#      rc_failed <num>  set local and overall rc status to <num>
#      rc_reset         clear both the local and overall rc status
#      rc_exit          exit appropriate to overall rc status
#      rc_active        checks whether a service is activated by symlinks
. /etc/rc.status

# Reset status of this service
rc_reset

# Return values acc. to LSB for all commands but status:
# 0	  - success
# 1       - generic or unspecified error
# 2       - invalid or excess argument(s)
# 3       - unimplemented feature (e.g. "reload")
# 4       - user had insufficient privileges
# 5       - program is not installed
# 6       - program is not configured
# 7       - program is not running
# 8--199  - reserved (8--99 LSB, 100--149 distrib, 150--199 appl)
# 
# Note that starting an already running service, stopping
# or restarting a not-running service as well as the restart
# with force-reload (in case signaling is not supported) are
# considered a success.

mdadm_BIN=/sbin/mdadm
mdadm_CONFIG="/etc/mdadm.conf"
mdadm_SYSCONFIG="/etc/sysconfig/mdadm"

# udev integration
if [ -x /sbin/udevadm ] ; then
    [ -z "$MDADM_DEVICE_TIMEOUT" ] && MDADM_DEVICE_TIMEOUT=60
else
    MDADM_DEVICE_TIMEOUT=0
fi

function _rc_exit {
	[ "x$2" != x"" ] && echo -n $2
	rc_failed $1
	rc_status -v
	rc_exit
}

case "$1" in
    start)
	echo -n "Starting MD RAID "
	
	mkdir -p /run/mdadm
	# restart mdmon (exits silently if there is nothing to monitor)
	/sbin/mdmon --all --takeover --offroot
	# Check for existence of needed config file and read it
	[ -r $mdadm_SYSCONFIG ] || _rc_exit 6 "... $mdadm_SYSCONFIG not existing "

	# Read config
	. $mdadm_SYSCONFIG
	
	[ "x$MDADM_CONFIG" != x"" ] && mdadm_CONFIG="$MDADM_CONFIG"

	# Check for missing binaries (stale symlinks should not happen)
        [ -x $mdadm_BIN ] || _rc_exit 5 "... $mdadm_BIN not installed "

	# Try to load md_mod
	[ ! -f /proc/mdstat -a -x /sbin/modprobe ] && /sbin/modprobe md_mod
	[ -f /proc/mdstat ] || _rc_exit 5 "... no MD support in kernel "

	# Wait for udev to settle
	if [ "$MDADM_DEVICE_TIMEOUT" -gt 0 ] ; then
	    /sbin/udevadm settle --timeout="$MDADM_DEVICE_TIMEOUT"
	fi

	if ! grep -qs '^[^#]*[^[:blank:]#]' $mdadm_CONFIG; then
		# empty or missing /etc/mdadm.conf, "unused"
		rc_status -u
	else
		# firstly finish any incremental assembly that has started.
		$mdadm_BIN -IRs
		$mdadm_BIN -A -s -c $mdadm_CONFIG
		# a status of 2 is not an error
		test $? -eq 0 -o $? -eq 2
		rc_status -v
	fi
	;;
    stop)
	echo -n "Not shutting down MD RAID - reboot/halt scripts do this."
	rc_failed 3
	# Remember status and be verbose
	rc_status -v
	;;
    status)
	echo -n "MD RAID arrays:"
	count=`grep -c ' active ' /proc/mdstat 2> /dev/null`
	case $count in
	    0 ) echo -n " No arrays active"; rc_failed 3;;
	    1 ) echo -n " 1 array active";;
	    * ) echo -n " $count arrays active";;
	esac

	rc_status -v
	;;
    reload)
	# We cannot really reload the kernel module, or reassemble the
	# arrays, but we can restart mdmon.  It will replace existing
	# mdmon, or exit quietly if there is nothing to do.
	echo -n "MD RAID: restarting mdmon if it is needed."
	/sbin/mdmon --all --takeover --offroot
	rc_status -v
	;;
    *)
	echo "Usage: $0 {start|stop|status|reload}"
	exit 1
	;;
esac
rc_exit

# vim:ft=sh
