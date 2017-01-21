#!/usr/bin/perl -w

# Check galera status
# (C) Mark Janssen -- Sig-I/O Automatisering
# 2013/09/10 -- Initial version
# 2017/01/21 -- Put config in variables for release

use strict;
use DBI;

# Hostname for Send-NSCA
my $hostname = qx/hostname/;
chomp($hostname);

# Connect to the database and keep using this connection
my $database = "mysql";
my $databasehost = "localhost";
my $databaseport = "3306";
my $checkuser = "galeracheck";
my $checkpassword = "replacewithyourpassword";
my $nagioshost = "nagios.local";
my $nscaconfig = "/usr/local/etc/send_nsca.cfg";
my $nscabin = "/usr/sbin/send_nsca";
my $galeraclustersize = "3";

my $dbh;

# Setup some globals
my $sth;
my $errstring = "";
my $errcount = 0;
my $loopcount = 0;
my $oldstatus = 0;
my $debug = 1;

my $downfile = "/tmp/mysql-down";     # Created when a check fails, to be used by keepalived
my $offfile = "/tmp/mysql-off";       # Created manually to force checks to fail, will create $downfile
my $pidfile = "/home/galeramon/mon_maria.pid";

sub writepid()
{
  open( PID, ">$pidfile" ) or die "Can't open PIDFILE\n";
  printf PID "$$";
  close( PID) ;
}

sub connectdb()
{
    if ( $dbh = DBI->connect("DBI:mysql:$database:$databasehost:$databaseport", $checkuser, $checkpassword ) )
  {
    $dbh->{mysql_auto_reconnect} = 1;
  }
  else
    {
    $errcount += 2;
    $errstring = "Can't connect to database";
    notifynsca();
    exit 2;
  }
}

# Tell Nagios (NSCA) what we found
sub notifynsca()
{
  my $status = $errcount;
  if ( $status > 2 )
  {
    $status = 2;
  }
  if ( $status == 0 )
  {
    $errstring = "OK"
  }

  open( NSCA, "|$nscabin -H $nagioshost -c $nscaconfig 2>&1 > /dev/null" ) or die "Can't open NSCA\n";
  printf NSCA "$hostname\tgalera_check\t$status\t$errstring ($loopcount)\n";
  print "$hostname\tgalera_check\t$status\t$errstring\n" if $debug;
  close( NSCA) ;
}

writepid();
connectdb();

# Keep looping through the checks
while( 1 == 1 )
{
  my @result;
  #
  # CHECK 1: show global status where variable_name="wsrep_local_state"
  #

  # Local state should be 4
  $sth = $dbh->prepare('show global status where variable_name="wsrep_local_state"');
  if (!$sth) {
      $errcount++;
      $errstring .= $dbh->errstr . "   ";
  }
  if (!$sth->execute) {
      $errcount++;
      $errstring .= $dbh->errstr . "   ";
  }
  @result = $sth->fetchrow_array();
  $sth->finish();

  if ( $result[1] != 4 )
  {
    $errcount++;
    $errstring .= "Local state not OK ";
  }

  #
  # CHECK 2: show global variables where variable_name="wsrep_on"
  #

  # wsrep_on should be on
  $sth = $dbh->prepare('show global variables where variable_name="wsrep_on"');
  if (!$sth) {
      $errcount++;
      $errstring .= $dbh->errstr . "   ";
  }
  if (!$sth->execute) {
      $errcount++;
      $errstring .= $dbh->errstr . "   ";
  }
  @result = $sth->fetchrow_array();
  $sth->finish();

  if ( $result[1] ne 'ON' )
  {
    $errcount++;
    $errstring .= "WSREP not ON  ";
  }

  #
  # CHECK 3: Cluster size
  #

  # wsrep_cluster_size should be 3 ($galeraclustersize)
  $sth = $dbh->prepare('select variable_name,variable_value from information_schema.global_status where variable_name = "wsrep_cluster_size"');
  if (!$sth) {
      $errcount++;
      $errstring .= $dbh->errstr . "   ";
  }
  if (!$sth->execute) {
      $errcount++;
      $errstring .= $dbh->errstr . "   ";
  }
  @result = $sth->fetchrow_array();
  $sth->finish();

  if ( $result[1] != '$galeraclustersize' )
  {
    $errcount++;
    $errstring .= "Cluster size not $galeraclustersize  ";
  }

  #
  # CHECK 4: Override check
  #

  if ( -e $offfile )
  {
    $errcount++; 
    $errstring .= "MySQL manually forced off  ";
  }
  else
  {
    if ( -e $downfile )
    {
      unlink $downfile;
    }
  }

  if ( $errcount != 0 )
  { 
    # Create downfile, so keepalived knows this node is not working correctly
    open(MYSQLDOWN,">$downfile");
    print MYSQLDOWN "";
    close( MYSQLDOWN );
  }


  #
  # After all the checks, report back to nagios if results are different
  # or this is the 30th concurrent check with the same results.
  # So we always tell nagios at least every 30 runs. 
  #

  if ( $errcount > 0 )
  {
    print "$errcount errors encountered: $errstring\n";
    if ( $oldstatus != $errcount )
    {
        notifynsca();
        $loopcount = 0;
    }
    else
    {
        $loopcount++;
    }
    $oldstatus = $errcount;
    $errcount = 0;
    $errstring = "";
  }
  else
  {
    if ( $oldstatus != $errcount )
    {
        notifynsca();
        $loopcount = 0;
    }
    else
    {
        $loopcount++;
    }
    $oldstatus = 0;
  }

  if ( ($loopcount % 30) == 0 )
  {
    notifynsca();
  }

  # Delay a bit before running again
  sleep 1;
}

# Disconnect from the database... though we should never get here
$dbh->disconnect();
unlink $pidfile;
