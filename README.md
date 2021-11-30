sysadmin
========

System-admin scripts

monitor.sh and monitor.rc
-------------------------

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

To be used with Nagios/Icinga compatible monitoring systems

check_ssd_attribs.pl
--------------------

Nagios/Icinga check-script to monitor various SMART attributes on (SSD) drives. Will calculate
the percentage of TBW (total bytes written), and monitor various other attributes used by
(for example) Samsung 840 Pro ssd's. 

To be used with Nagios/Icinga compatible monitoring systems

mon_maria.pl
------------

Monitoring script for galera clusters, check correct values in the following settings:
  - wsrep_local_state
  - wsrep_on
  - wsrep_cluster_size
And the option to force a node offline manually. This script can be used as a loadbalancer check script to judge the health of the cluster-node.

check_activemq
--------------

Will monitor the amount of messages and consumers in various activeMQ queues, and alert if there
are too many messages, or too little consumers. Limits can be supplied per queue, with a fallback
default option. Limits can be specified using a cron-like syntax to specify when they should apply.

The config, and URL to the activeMQ webpage should be specified in the code at this time.

To be used with Nagios/Icinga compatible monitoring systems

check_activemq_mem
------------------

Check the ActiveMQ memory (Store/Memory/Temp) usage by parsing the ActiveMQ webpage

To be used with Nagios/Icinga compatible monitoring systems


check-es-indexes
----------------

Check if the specified ElasticSearch index(es) have data in them. The URL to the ES instance,
and the indexes to be monitored need to be specified in the script.

To be used with Nagios/Icinga compatible monitoring systems


check_haproxy
-------------

By: Stéphane Urbanovski <stephane.urbanovski@ac-nancy-metz.fr>

To be used with Nagios/Icinga compatible monitoring systems

check_megaraid_sas
------------------

By: Jonathan Delgado, delgado@molbio.mgh.harvard.edu
With various patches.

Check the array and disk status of disks attached to megaraid controllers. Uses 'MegaCli'.
This version is patched to handle JBOD disks and optionally ignore 'other' errors as reported by megacli,

To be used with Nagios/Icinga compatible monitoring systems

check_ssl_certificate
---------------------

By: David Alden <alden@math.ohio-state.edu>
Patched to alert on expired certificates

This script will check if an SSL certificate is going to expire.

To be used with Nagios/Icinga compatible monitoring systems

check_system_pp
---------------

By: FBA?
Patched to read processes and ports to monitor from seperate files

Check if processes and ports are running/open as expected.

To be used with Nagios/Icinga compatible monitoring systems

nagios-lvm-space
----------------

Check free (unallocated) space in LVM volume groups

To be used with Nagios/Icinga compatible monitoring systems

parse-backupninja-logs.sh
-------------------------

Check the status of backups made by backupninja by parsing it's logfiles.

To be used with Nagios/Icinga compatible monitoring systems

split-hotfolder.sh
------------------

Move files coming into a directory to one of multiple other directories.
