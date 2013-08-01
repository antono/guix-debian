#
# Regular cron jobs for the guix package
#
0 4	* * *	root	[ -x /usr/bin/guix_maintenance ] && /usr/bin/guix_maintenance
