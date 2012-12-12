#!/bin/bash

# NRPE-Alternative without active checks
# (C) 2012 Mark Janssen, Sig-I/O Automatisering 
# License: CC-BY-3.0 http://creativecommons.org/licenses/by/3.0/
#
# 2012/10/08: Version 0.5, initial version, published on sig-io.nl
# 2012/12/12: Version 0.6, use mutex from http://wiki.bash-hackers.org/howto/mutex
# 2012/12/12: Version 0.7, use monitor.rc file for host-specific configuration

# Run some nagios checks, and report their results using nsca

# Load settings
. /root/scripts/monitor.rc

LOCKDIR=/var/run/monitor
PIDFILE=${LOCKDIR}/pid

# Acquire lock...
if mkdir "${LOCKDIR}" &>/dev/null; then
    trap 'ECODE=$?;
          rm -rf "${LOCKDIR}"' 0
    echo "$$" >"${PIDFILE}" 

    # the following handler will exit the script on receiving these signals
    # the trap on "0" (EXIT) from above will be triggered by this trap's "exit" command!
    trap 'echo "[$0] Killed by a signal." >&2
          exit 3' 1 2 3 15

    # Run actual checks
    for CHECK in "${CHECKS[@]}"
	do
	CHECKNAME=`echo ${CHECK} | awk -F\| '{print $1}'`
	CHECKCMD=`echo ${CHECK} | awk -F\| '{print $2}'`

	DATA=`${CHECKPATH}/${CHECKCMD}`
	RETVAL=$?
	#echo "Data = $DATA"

	echo "${HOSTNAME}	${CHECKNAME}	${RETVAL}	${DATA}" | ${NSCA} -H ${NSCASERVER} -c ${NSCACONF}
	done > /dev/null
	
else
    # lock failed, now check if the other PID is alive
    OTHERPID="$(cat "${PIDFILE}")"
 
    if [ $? != 0 ]; then
      echo "lock failed, PID ${OTHERPID} is active" >&2
      exit 2
    fi
 
    if ! kill -0 $OTHERPID &>/dev/null; then
        # lock is stale, remove it and restart
        rm -rf "${LOCKDIR}"
        exec "$0" "$@"
    else
        # lock is valid and OTHERPID is active - exit, we're locked!
        exit 2
    fi
 
fi

