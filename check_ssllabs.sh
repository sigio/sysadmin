#!/bin/bash

# Query the ssllabs tests for a site
# (C) 2012 Mark Janssen, Sig-I/O Automatisering
# License: CC-BY-3.0 http://creativecommons.org/licenses/by/3.0/

SITE=$1
SERVER=$2

NSCA=/usr/sbin/send_nsca
NSCACONF=/etc/send_nsca.cfg
NSCASERVER=your.nagios.system
HOSTNAME=`hostname`

if [[ -z ${SERVER} ]]; then
  SCORE=`curl -k -s "https://www.ssllabs.com/ssltest/analyze.html?d=${SITE}" | grep -A 1 "chartValue" | tr -d '\t' | grep -oE "[0-9]([0-9][0-9]|[0-9])"`
else
  SCORE=`curl -k -s "https://www.ssllabs.com/ssltest/analyze.html?d=${SITE}&s=${SERVER}" | grep -A 1 "chartValue" | tr -d '\t' | grep -oE "[0-9]([0-9][0-9]|[0-9])"`
fi

TOTAL_SCORE=`echo ${SCORE} | tr -d '\n'`
OK=3

for PERCENTAGE in ${SCORE};
do
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
  break
fi
done

echo "${HOSTNAME}	ssllabs_${SITE}	${OK}	SSLLabs score for ${SITE} = ${TOTAL_SCORE}" | ${NSCA} -c ${NSCACONF} -H ${NSCASERVER}
