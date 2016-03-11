#!/usr/bin/perl -w

# check_ssd_attribs
# Copyright (C) 2016  Mark Janssen -- Sig-I/O Automatisering, mark@sig-io.nl
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

use strict;

use Getopt::Std;
use lib qw(/usr/lib/nagios/plugins /usr/lib64/nagios/plugins); # possible pathes to your Nagios plugins and utils.pm
use utils qw(%ERRORS);

our($opt_h, $opt_d, $opt_t, $opt_T, $opt_D);

our $failcount = 0;
our $warntext = "";
our $status = "OK";

getopts('hd:t:T:D');

if ( $opt_h ) {
        print "Usage: $0 -d drives [-t smartctl-device] [-T TBWritten]\n";
        print "       -d is the device to check (ex: /dev/sdb)\n";
        print "       -t is the device type for smartctl (ex: sat+megaraid,3)\n";
        print "       -T Warranted number of TB's written\n";
        exit;
}

our $warrantytbs = 100;
$warrantytbs = $opt_T if $opt_T;

my $smartctl = '/usr/sbin/smartctl'; 	# Path to smartctl
my $deviceopts = "";
$deviceopts .= "-d $opt_t " if $opt_t;
$deviceopts .= "$opt_d" if $opt_d;

open (SMARTDATA, "$smartctl $deviceopts -A -f brief |") || exitreport('UNKNOWN', "error: Could not execute $smartctl $deviceopts");
while( <SMARTDATA> )
{
	next if $_ =~ /^smartctl/;
	next if $_ =~ /^Copyright/;
	next if $_ =~ /^$/;
	next if $_ =~ /^=== START/;
	next if $_ =~ /^SMART Attri/;
	next if $_ =~ /^Vendor Spec/;
	next if $_ =~ /^ID#/;
	next if $_ =~ /^                  /;

	chomp;
	print "Got line: '$_'\n" if $opt_D;
	my ($id, $attr, $flags, $value, $worst, $thresh, $fail, $raw) = split;
	print "ID = $id, Attr = $attr, Fail = $fail, Raw = $raw\n" if $opt_D;

	if( $fail ne "-" )
	{
		$failcount++;
		$warntext .= "Attr $attr fail: $fail ";
	}

	# 177: Wear leveling count
	# The value attribute is a percentage, starting at 100
	# A disk will continue running when it reaches <20% but then
	# Used-Block-Reserve will be going up.
	# Link: http://techreport.com/review/27436/the-ssd-endurance-experiment-two-freaking-petabytes/2
	if( $id == '177' ) # Wear Leveling count
	{
		$failcount++ if ( $value <= 60 );
		$failcount++ if ( $value <= 20 );
		$warntext .= "WLC: $value " if ( $value <= 70 );
	}

	# 179: Used_Rsvd_Blk_Cnt_Tot
	# Total reserved block percentage still available
	if ( $id == '179' ) # Used_Rsvd_Blk_Cnt_Tot
	{
		$failcount++ if ( $value <= 80 );
		$failcount++ if ( $value <= 40 );
		$warntext .= "Reserved Blocks: $value% " if ($value <= 80);
	}

	# 181: Program_Fail_Cnt_Total
	# 182: Erase_Fail_Count_Total
	# 183: Runtime_Bad_Block
	# 187: Reported_Uncorrect
	if ( $id =~ /181|182|183|187/)
	{
		$failcount++ if ( $value <= 50 );
		$warntext .= "$attr $value " if ($value <= 50);
	}
	
	# 241: TOTAL LBA's Written
	# Total number of LBA's (512 byte sectors) written to disk
	# SSD's are warranted against a MAX number of writes
	# SAMSUNG 840 PRO's are warranted against 72 TB or 40GB/day for 5 years
	if( $id == '241' ) # Total LBA's written / Samsung
	{
		my $tbs = int($raw * 512 / 1024 / 1024 / 1024 / 1024);
		my $warrantypercentage = int( $tbs / $warrantytbs * 100 );
		$warntext .= "Total TB's written: $tbs out of warranted $warrantytbs ($warrantypercentage%)\n";
		$failcount++ if ( $warrantypercentage >= 90 );
		$failcount++ if ( $warrantypercentage >= 130 );
	}
}

my $retval = $failcount;
$retval = 2 if ($failcount >= 2 );
$status = "CRITICAL" if ($retval == 2);
$status = "WARNING" if ($retval == 1);
    
print STDOUT "$status: $warntext";
exit $retval;
