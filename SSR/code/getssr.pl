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

# usage: ./getssr.pl >> ssr.history

# first, find the most recent good results in ssr.history

$dir = "/nfs/farm/g/glast/u55/rac/LATmetrics/SSR";

$tail = `tail -1 $dir/ssr.history`;
@f = split(' ',$tail);
$tdate = sprintf "%04i-%02i-%02i",@f[8,9,10];
if ($f[11] > 20) { $tdate = `date --date="$tdate + 1 day" +"%F"` };
chomp $tdate;
$tdate_s = `date --date="$tdate" +"%s"`;

$today = `date +"%F"`;
chomp $today;
$today_s = `date --date="$today" +"%s"`;

$deld = ($today_s - $tdate_s)/86400;
if ($deld > 1) { print STDERR "$0: processing $deld days between $tdate and $today\n" };

$cmd = "$dir/SsrUsage.py -b '$tdate 00:00:00' -e '$today 00:00:00' -d";
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
