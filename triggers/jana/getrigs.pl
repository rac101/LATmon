#!/usr/local/bin/perl -w

# get daily LAT trigger rate
# here is the format of the TriggerRate.py command:
# TriggerRate2.py -b '-1 days' -e '2012-06-30 00:00:00' -d -n
#
# typical lines from trigrate.jana
# Daily Ave (2012-06-17 23:59:57 - 2012-06-19 00:00:05) :        164526066 triggers / 86398 sec ->      1904.3 Hz
# Daily Ave  2012 06 18 23 59 57   2012 06 20 00 00 03           165352890 triggers / 86398 sec  >      1913.9 Hz

# Robert Cameron
# June 2012

# usage: ./getrigs.pl >> trigrate.jana

# first, find the most recent good results in trigrate.jana

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

    $dir = "/u/gl/rac/LATmetrics/triggers/jana";

    $tail = `tail -1 $dir/trigrate.jana`;
    @f = split(' ',$tail);
    $tdate = sprintf "%04i-%02i-%02i",@f[8,9,10];
    if ($f[11] > 20) { $tdate = `date --date="$tdate + 1 day" +"%F"` };
    chomp $tdate;
    $tdate_s = `date --date="$tdate" +"%s"`;

    $now = `date --date='yesterday' +"%F"`;
    chomp $now;
    $now_s = `date --date="$now" +"%s"`;

# check date range
    $deld = ($now_s - $tdate_s)/86400;
    if ($deld > 1) { print STDERR "$0: processing $deld days between $tdate and $now\n" };

    die "$0: $dir/trigrate.jana is up to date. Ending.\n" unless ($deld);

# Add 1 minute to the end time below, to ensure the day boundary is crossed, 
# so that the daily trigger rate is reported by Jana's python script

    $cmd = "$dir/TriggerRate2.py -b '$tdate 00:00:00' -e '$now 00:01:00' -d -n";
#print STDERR "$0: About to execute the command: $cmd\n";
    @result = `$cmd`;
#print STDERR "$0: the command execution result is: \n",@result;

# ensure only good results go into ssr.history

    foreach (@result) { 
	last if (/WARNING/);
	next unless (/Daily Ave/);
	s/[-:\(\)]/ /g;
	s/\s{2,}/ /g;
	@f = split;
#    print STDERR "before time checks: ",$_;
	if (abs(86400-$f[17]) > 30) { print STDERR "$0: not ~86400s in $_" };
	last if (abs(86400-$f[17]) > 3600);
#    print STDERR "before 2nd time checks: ",$_;
	$hms = $f[11]*3600+$f[12]*60+$f[13];
	if ($hms > 60 and abs(86400-$hms) > 60) { print STDERR "$0: not ending at ~midnight in $_" };
	last if ($hms > 3600 and abs(86400-$hms) > 3600);
	print $_;
    }
}  # end of main sub
