#!/bin/sh

# Clear the ssllabs cache for a site, run max 1x per day
# (C) 2012 Mark Janssen, Sig-I/O Automatisering
# License: Public Domain

curl -k -o /dev/null -s https://www.ssllabs.com/ssltest/clearCache.html?d=$1
sleep 5
curl -k -o /dev/null -s https://www.ssllabs.com/ssltest/analyze.html?d=$1
