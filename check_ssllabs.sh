#!/bin/sh

# Query the ssllabs tests for a site
# (C) 2012 Mark Janssen, Sig-I/O Automatisering
# License: CC-BY-3.0 http://creativecommons.org/licenses/by/3.0/

SITE=$1

NSCA=/usr/sbin/send_nsca
NSCACONF=/etc/send_nsca.cfg
NSCASERVER=your.nagios.system
HOSTNAME=`hostname`

PERCENTAGE=`curl -k -s https://www.ssllabs.com/ssltest/analyze.html?d=${SITE} | grep -A 1 percentage_g | tail -1 | tr -d ' \n\r'`

OK=3
if [[ ${PERCENTAGE} -ge 85 ]];
then
        OK=0
else
        if [[ ${PERCENTAGE} -ge 75 ]];
        then
                OK=1;
        else
                OK=2;
        fi
fi

echo "${HOSTNAME}	ssllabs_${SITE}	${OK}	SSLLabs score for ${SITE} = ${PERCENTAGE}" | ${NSCA} -c ${NSCACONF} -H ${NSCASERVER}

