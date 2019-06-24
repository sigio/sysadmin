#!/usr/bin/perl

# © 2019 -- Sig-I/O Automatisering -- Mark Janssen
# 2019/06/24: Version 1.0 -- MIT Licensed

# Process posted NSCA results from send_nsca_http_post, and forward them
# to the nagios.cmd / icinga.cmd socket

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

sub output_top($);
sub output_error($);
sub output_end($);
sub process_data($);

my $q = new CGI;

print $q->header();
output_top($q);

if ($q->param()) {
    process_data($q);
}

output_end($q);
exit 0;

# Outputs the start html tag, stylesheet and heading
sub output_top($) {
    my ($q) = @_;
    print $q->start_html();
}

sub output_error($) {
    my ($q) = @_;
    print $q->div("Access Denied");
    print $q->end_html;
}

# Outputs a footer line and end html tags
sub output_end($) {
    my ($q) = @_;
    print $q->end_html;
}

# Displays the results of the form
sub process_data($) {
    my ($q) = @_;

    my $hname = $q->param('hostname');
    my $cname = $q->param('checkname');
    my $res = $q->param('result');
    my $edata = $q->param('extradata');
    my $now = time();

	# Limit checks to some specific domain
    if ( $hname =~ /some\.subdomain\.tld/ )
    {
        open(my $fh, '>>', '/var/lib/icinga/rw/icinga.cmd');
        print $fh "[$now] PROCESS_SERVICE_CHECK_RESULT;$hname;$cname;$res;$edata\n";
        close $fh;
    }
    else
    {
        output_error($q);
    }
}
