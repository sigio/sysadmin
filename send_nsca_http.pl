#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;

# © 2019 -- Sig-I/O Automatisering -- Mark Janssen
# 2019/06/24: Version 1.0 -- MIT Licensed

# Drop-in replacement for send_nsca, takes check results from stdin
# seperated by tabs (like normal send_nsca), and submit them as http-post
# fields to the specified URL
# Use nsca-receive-http.cgi (also in this repo) to process the results

# Change this to the URL of our nsca-receive-http.cgi
my $url = 'https://hostname/nsca/post.cgi';
my $ua  = LWP::UserAgent->new(); 

while (<STDIN>)
{
    chomp;
    my ($hostname, $checkname, $retval, $data) = split('\t', $_);

    my %form;
    $form{'hostname'}=$hostname;
    $form{'checkname'}=$checkname;
    $form{'retval'}=$retval;
    $form{'extradata'}=$data;

    my $response = $ua->post( $url, \%form ); 
    my $content = $response->as_string();

    print $content;
}
