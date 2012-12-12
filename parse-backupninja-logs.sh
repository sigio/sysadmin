#!/bin/bash

# Parse backupninja log-files to report backup-status to nagios-nsca
# (C) 2012 Mark Janssen, Sig-I/O Automatisering
# License: CC-BY-3.0 http://creativecommons.org/licenses/by/3.0/

# Check logfiles of backups for last-run time and exit status
# If run without arguments, check all files
# if run with a hostname, only check that specific logfile

TODAY=`date +"%b %d"`
YESTERDAY=`date -d yesterday +"%b %d"`
WARN=0
WARNTXT=""
SEND_NSCA=/usr/sbin/send_nsca
NSCA_CONF=/etc/send_nsca.cfg
NSCAHOST=your.nagios.host
LOGPATH=/path/to/backupninja/reports

cd ${LOGPATH}

if [[ $# -eq '0' ]]; then
        FILTER="*.log"
else
        if [[ -z $1 ]]; then
                FILTER="*.log"
        else
                case "$1" in
                        somehost | someotherhost )
                                echo "OK: Backups for host $1 are disabled"
                                exit 0;
                                ;;
                esac
                FILTER=$1.log
        fi
fi

for file in ${FILTER}
do
        host=`basename $file .log`
        if [[ "$host" != "backupninja" ]]; then
                data=`grep "finished action" $file | tail -n1`
                timestamp=`echo $data | awk '{print $1,$2,$3}'`
                datum=`echo $data | awk '{print $1,$2}'`
                state=`echo $data | awk '{print $9}'`

                if [[ ( "$datum" != "$TODAY" ) && ( "$datum" != "$YESTERDAY" ) ]]; then
                        WARNTXT="${WARNTXT}Backup of host: $host is STALE (date: $timestamp) "
                        let WARN=$WARN+1
                        echo "$host     ninjabackup     1       Backup is STALE ($timestamp)\n" | ${SEND_NSCA} -H ${NSCAHOST} -c ${NSCA_CONF} 2>&1 > /dev/null
                elif [[ "$state" != "SUCCESS" ]]; then
                        WARNTXT="${WARNTXT}Backup of host: $host finished at '$timestamp' with state '$state' "
                        echo "$host     ninjabackup     2       Backup ${state}\n" | ${SEND} -H ${NSCAHOST} -c ${NSCA_CONF} 2>&1 > /dev/null
                        let WARN=$WARN+1
                else
                        echo "$host     ninjabackup     0       Backup ${state}\n" | ${SEND} -H ${NSCAHOST} -c ${NSCA_CONF} 2>&1 > /dev/null

                fi
        fi
done

if [[ "$WARN" -eq 0 ]]; then
        echo "All backups completed OK"
        exit 0;
else
        echo "${WARN} backup messages: ${WARNTXT}"
        exit 2;
fi

echo "WARNING, end of script reached"
exit 1;

