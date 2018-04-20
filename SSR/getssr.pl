#!/usr/local/bin/perl -w

# get daily SSR Usage
# here is the format of the SsrUsage.py command:
# SsrUsage.py -b '-1 days' -e '2012-06-30 00:00:00' -d                                                                                             
#
# typical lines from ssr.history
# Daily Ave  2012 06 16 23 59 58   2012 06 17 23 59 58    126.620 Gbits 86399 sec  > 126.620 Gbits day 1.466 Mbits sec
# Daily Ave  2012 06 17 23 59 58   2012 06 18 23 59 58    128.105 Gbits 86399 sec  > 128.106 Gbits day 1.483 Mbits sec
# Daily Ave  2012 07 03 00 00 07   2012 07 04 00 00 07    128.197 Gbits 86399 sec  > 128.197 Gbits day 1.484 Mbits sec
# Daily Ave  2012 07 04 00 00 07   2012 07 05 00 00 07    127.300 Gbits 86400 sec  > 127.299 Gbits day 1.473 Mbits sec

# Robert Cameron
# June 2012
# July 2013: allow WARNING messages to go to STDOUT
# August 2013: allow for WARNING messages being appended to the daily cumulative history file

# usage: ./getssr.pl >> ssr.history

# first, find the most recent good results in ssr.history

use warnings;
#use File::Basename;
use Try::Tiny;

#$sn = basename($0);

use strict 'subs';
use strict 'refs';

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 300;
    main();
    alarm 10;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: timed out\n";
}
finally {
#    print "done\n";
};

sub main {
    $dir = "/u/gl/rac/LATmetrics/SSR";

    @tail = ();
    $nlines = 0;
    until ($tail[0] and $tail[0] =~ /^ Daily Ave/) {
	$nlines++;
	@tail = `tail -$nlines $dir/ssr.history`;
    }
    if ($nlines > 1) { print STDERR "$0: needed to tail $nlines lines in ssr.history\n" };
    @f = split(' ',$tail[0]);
    $ssrdate = sprintf "%04i-%02i-%02i",@f[8,9,10];
    if ($f[11] > 20) { $startdate = `date --date="$ssrdate + 1 day" +"%F"` };
    chomp $startdate;
    $startdate_s = `date --date="$startdate" +"%s"`;
    
    $day = `date --date="today 00:00:00" +"%F %s"`;
    ($today,$today_s) = split(" ",$day);

    $deld = ($today_s - $startdate_s)/86400;
    if ($deld > 1) { print STDERR "$0: processing $deld days from $startdate to $today\n" };
    
    $cmd = "$dir/SsrUsage.py -b '$startdate 00:00:00' -e '$today 00:00:00' -d";
#print STDERR "$0: About to execute the command: $cmd\n";
    @ssr = `$cmd`;
    
# ensure only good results go into ssr.history
    
    foreach (@ssr) { 
	if (/WARNING/) { print $_; next };
	next unless (/Daily Ave/);
	s/[-:\/\(\)]/ /g;
	@f = split;
	last if (abs(86400-$f[16]) > 30);
	$hms = $f[11]*3600+$f[12]*60+$f[13];
	last if ($hms > 60 and abs(86400-$hms) > 60);
	print $_;
    }
}  # end of main sub
