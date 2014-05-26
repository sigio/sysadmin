sysadmin
========

System-admin scripts


monitor.sh
----------

nagios nrpe alternative, use with cron and send_nsca to have a minimalistic
nrpe alternative. Can be used for 'unreachable' hosts.

Host-specific configuration (paths / checks to run) goes in monitor.rc file

If you are running a MQTT server, you can have monitor.sh also report status updates and warnings to a MQTT topic. This required mosquitto_pub to be present on the system.

check_ssllabs.sh
----------------

Check Qualys ssllabs.com site for score/configuration of a https certificate
Trigger nagios warning/error when score drops below 85.
Don't run more then 1x per hour. Run the reset_ssllabs.sh script no more then 1x per day.
It can take up to 5 minutes between a reset and a cache-update.
