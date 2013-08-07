#!/bin/sh
### BEGIN INIT INFO
# Provides:          guix
# Required-Start:    $network $local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Guix Worker
# Description:       Worker porcess for guix package manager
### END INIT INFO

# Author: Anton Vasiljev <self@antono.info>

# PATH should only include /usr/* if it runs after the mountnfs.sh script

GUIX_GROUP='guix'
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC=guix
NAME=guix
DAEMON=/usr/bin/guix-daemon
DAEMON_ARGS="--max-jobs=4 --build-users-group=$GUIX_GROUP"
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
# . /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    start-stop-daemon --start --make-pidfile --background \
        --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
	|| return 1
    start-stop-daemon --start --make-pidfile --background \
        --quiet --pidfile $PIDFILE --exec $DAEMON -- \
	$DAEMON_ARGS \
	|| return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2
    start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
    [ "$?" = 2 ] && return 2
    rm -f $PIDFILE
    return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
    do_stop
    do_start
    return 0
}

case "$1" in
    start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC " "$NAME"
        do_start
        case "$?" in
	    0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
	    2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
        ;;
    stop)
	[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
	    0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
	    2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
    status)
        status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
        ;;
    restart|force-reload)
	#
	# If the "reload" option is implemented then remove the
	# 'force-reload' alias
	#
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	    0|1)
		do_start
		case "$?" in
		    0) log_end_msg 0 ;;
		    1) log_end_msg 1 ;; # Old process is still running
		    *) log_end_msg 1 ;; # Failed to start
		esac
		;;
	    *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
    *)
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	exit 3
	;;
esac
