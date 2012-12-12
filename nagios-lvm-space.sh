#!/bin/sh -e

# Check free space in LVM volume-group
# (C) 2012 Mark Janssen, Sig-I/O Automatisering
# License: CC-BY-3.0 http://creativecommons.org/licenses/by/3.0/

VOLGROUP=$1
WARNSIZE=200
CRITSIZE=100
CODE=0
TXTCODE="OK"
TXT="Volume group ${VOLGROUP} free-space: "
SEND_NSCA=/usr/sbin/send_nsca
HOSTNAME=`hostname -s`
NSCAHOST=your.nagios.host
NSCA_CONF=/etc/nagios/send_nsca.cfg

FREE=`/sbin/vgs --noheadings --units=G --nosuffix -o vg_name,vg_free ${VOLGROUP} | awk '{print $2}' | awk -F. '{print $1}'`

if [ ${FREE} -lt ${WARNSIZE} ]; then
        CODE=1
        TXTCODE="WARNING"
fi

if [ ${FREE} -lt ${CRITSIZE} ]; then
        CODE=2
        TXTCODE="CRITICAL"
fi


echo "${HOSTNAME}       lvm-free-space  ${CODE} ${TXTCODE}: ${TXT} ${FREE}\n" | ${SEND_NSCA} -H ${NSCAHOST} -c ${NSCA_CONF} 2>&1 > /dev/null
exit 0

