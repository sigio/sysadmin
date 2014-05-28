#!/bin/bash

# Query the ssllabs tests for a site
# (C) 2012-2014 Mark Janssen, Sig-I/O Automatisering
# License: CC-BY-3.0 http://creativecommons.org/licenses/by/3.0/

SITE=$1
SERVER=$2

NSCA=/usr/sbin/send_nsca
NSCACONF=/etc/send_nsca.cfg
NSCASERVER=your.nagios.system
HOSTNAME=`hostname`

if [ -z ${SERVER} ]; then
  URL="https://www.ssllabs.com/ssltest/analyze.html?d=${SITE}"
else
  URL="https://www.ssllabs.com/ssltest/analyze.html?d=${SITE}&s=${SERVER}"
fi

SCORE=`curl -k -s "${URL}" | grep rating_g | tr '<>/' '   ' | awk '{print $6}'`

OK=3

if [[ "x${SCORE}" == "xA" ]]; then
  OK=0
elif  [[ "x${SCORE}" == "xA+" ]]; then
  OK=0
elif  [[ "x${SCORE}" == "xA-" ]]; then
  OK=0
elif  [[ "x${SCORE}" == "xB" ]]; then
  OK=1
else
  OK=2
fi

echo "${HOSTNAME}	ssllabs_${SITE}	${OK}	SSLLabs rating for ${SITE} = ${SCORE}" | ${NSCA} -c ${NSCACONF} -H ${NSCASERVER}
