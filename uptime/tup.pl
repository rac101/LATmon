#!/usr/local/bin/perl -w

# collect daily uptime numbers using Jana's Uptime.py script

# Robert Cameron
# April 2012
# August 2013
# april 2018 : add Try around main program

# usage: ./tup.pl >> tup.out

# a typical line start from tup.out is:
# 2012-10-07 23:59:55.140074 2012-10-09 00:00:04.140105 86408.000030

use Try::Tiny;

use strict 'subs';
use strict 'refs';

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 90;
    main();
    alarm 10;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: Try timed out\n";
}
finally {
#    print "done\n";
};

#####################################
sub main {

# first, find the most recent results in "tup.out"

    $wdir = "/u/gl/rac/LATmetrics/uptime";
    @tail = `tail $wdir/tup.out`;
    $tail = '';
    until ($tail =~ /:/)  { $tail = pop(@tail) };
    @f = split(' ',$tail);
    ($h,$m,$m) = split(':',$f[3]);
    $startdate = $f[2];
    if ($h > 1) { $startdate = `date --date="$f[2] + 1 day" +"%F"` };
    chomp $startdate;
    $startsec = `date -u --date="$startdate 00:00:00" +'"%s"'`;
    $startsec =~ s/\D//g;
#print STDERR "startdate $startdate & startsec $startsec\n";

    $enddate = `date -u --date="-3 days" +"%F"`;
    chomp $enddate;
    $endsec = `date -u --date="$enddate 00:00:00" +'"%s"'`;
    $endsec =~ s/\D//g;
#print STDERR "enddate $enddate & endsec $endsec\n";
    
    $ndays = ($endsec - $startsec)/86400.0; 
    if ($ndays > 1) { print STDERR "$0: Working on $ndays days, for day range $startdate to $enddate\n" };
    
    foreach (0..$ndays-1) { 
	$workdate = `date --date="$startdate + $_ day" +"%F"`;
#    $startdate = `date --date="$startdate + 1 day" +"%F"`;
	chomp $workdate;
#    $cmd = "/nfs/farm/g/glast/u55/rac/LATmetrics/uptime/Uptime.py -b '$workdate 00:00:00' -e '+1 days' -a -x";
	$cmd = "$wdir/Uptime.py -b '$workdate 00:00:00' -e '+1 days' -a -x";
#    print STDERR "$cmd\n";
	@res = `$cmd`;
	foreach (@res) { 
	    next unless /Summary/;
	    s/Summary: //;
	    print $_;
	}
    }  # end of days loop
}  # end of main sub
