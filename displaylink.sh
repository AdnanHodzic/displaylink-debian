#!/bin/sh
# kFreeBSD do not accept scripts as interpreters, using #!/bin/sh and sourcing.
if [ true != "$INIT_D_SCRIPT_SOURCED" ] ; then
    set "$0" "$@"; INIT_D_SCRIPT_SOURCED=true . /lib/init/init-d-script
fi
### BEGIN INIT INFO
# Provides:          displaylink
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: DisplayLink driver
# Description:       Manage DisplayLink driver
### END INIT INFO

# Author: Gabriel Hondet <gabriel.hondet@gmail.com>

DESC="DisplayLink driver"
DAEMON=/opt/displaylink/DisplayLinkManager
NAME="displaylink"
PIDFILE=/var/run/$NAME.pid
START_ARGS="--background"
