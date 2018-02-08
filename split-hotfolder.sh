#!/bin/bash

# Function: Split files in specified hotfolder into various queues
# Mark Janssen -- Sig-I/O Automatisering -- 2018/02/08

ARGS=$#

if [ $# -lt 3 ]; then
	echo "illegal number of parameters"
	echo "Usage: $0 <hotfolder> <output1> <output2> [ <output-n> ] ..."
	echo "\tminimal 2 outputs"
	exit 1;
fi

# First argument is source location directory
INPUT=$1

# Additional directories (at least 2) are destination paths to devide over
shift
declare -a OUTPUTS=($*)
NROUT=${#OUTPUTS[@]}

FILENUM=0
for file in ${INPUT}/*
do
	let "OUTMOD=$FILENUM%$NROUT"
#	echo "Found file '$file' (filenum: $FILENUM)"
#	echo "Moving file to output $OUTMOD, which is: ${OUTPUTS[$OUTMOD]}"
	mv -v "$file" "${OUTPUTS[$OUTMOD]}"
	((FILENUM++))
done
