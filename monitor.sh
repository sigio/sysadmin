#!/bin/bash

# NRPE-Alternative without active checks
# (C) 2012 Mark Janssen, Sig-I/O Automatisering 
# License: CC-BY-3.0 http://creativecommons.org/licenses/by/3.0/
#
# 2012/10/08: Version 0.5, initial version, published on sig-io.nl
# 2012/12/12: Version 0.6, use mutex from http://wiki.bash-hackers.org/howto/mutex
# 2012/12/12: Version 0.7, use monitor.rc file for host-specific configuration
# 2014/05/01: Version 0.71, send host 'check' result
# 2014/05/26: Version 0.8, optionally publish to mqtt 

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

    # Send host check result
    echo "${HOSTNAME}	0	Checked by $0" | ${NSCA} -H ${NSCASERVER} -c ${NSCACONF} > /dev/null
    if [ ${MQTTHOST} ]; then
        mosquitto_pub -h ${MQTTHOST} -t ${MQTTTOPIC} -m "{'host':'${HOSTNAME}', 'check':'${HOSTNAME}', 'returncode':'0', 'data':'Checked by $0'}"
    fi

    # Run actual checks
    for CHECK in "${CHECKS[@]}"
    do
      CHECKNAME=`echo ${CHECK} | awk -F\| '{print $1}'`
      CHECKCMD=`echo ${CHECK} | awk -F\| '{print $2}'`

      DATA=`${CHECKPATH}/${CHECKCMD}`
      RETVAL=$?

      echo "${HOSTNAME}	${CHECKNAME}	${RETVAL}	${DATA}" | ${NSCA} -H ${NSCASERVER} -c ${NSCACONF}

      if [ ${MQTTHOST} ]; then
        mosquitto_pub -h ${MQTTHOST} -t ${MQTTTOPIC} -m "{'host':'${HOSTNAME}', 'check':'${CHECKNAME}', 'returncode':'${RETVAL}', 'data':'${DATA}'}"
        if [ ${RETVAL} -ne 0 ]; then
          mosquitto_pub -h ${MQTTHOST} -t ${MQTTWARNTOPIC} -m "{'host':'${HOSTNAME}', 'check':'${CHECKNAME}', 'returncode':'${RETVAL}', 'data':'${DATA}'}"
        fi
      fi

    done > /dev/null
else # lock failed, now check if the other PID is alive
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

