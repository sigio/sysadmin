#!/bin/sh

CURL=/usr/bin/curl

HOSTNAME="$1"
BASEURL="http://${HOSTNAME}:9200"

URLS=(
'some/index'
'some/other/index'
)

ERRSTR=""

for URL in "${URLS[@]}"
do
        DATA="`${CURL} -s ${BASEURL}/${URL}/_count | awk -F, '{print $1}' | tr '{}:' ' '`"

        COUNT="`echo ${DATA} | awk '{print $2}'`"
        if [ $COUNT -lt 1 ]; then
                ERRSTR="${ERRSTR}${URL} empty "
        fi
done

if [ ! -z "${ERRSTR}" ]; then
        echo "WARNING ElasticSearch indexes empty: ${ERRSTR}"
        exit 1
else
        echo "OK - ElasticSearch indexes are populated"
        exit 0
fi

