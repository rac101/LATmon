#!/usr/local/bin/perl -w

# check time continuity of history of daily SSR Usage

# typical lines from ssr.history
# Daily Ave  2012 06 16 23 59 58   2012 06 17 23 59 58    126.620 Gbits 86399 sec  > 126.620 Gbits day 1.466 Mbits sec
# Daily Ave  2012 06 17 23 59 58   2012 06 18 23 59 58    128.105 Gbits 86399 sec  > 128.106 Gbits day 1.483 Mbits sec
# Daily Ave  2012 07 03 00 00 07   2012 07 04 00 00 07    128.197 Gbits 86399 sec  > 128.197 Gbits day 1.484 Mbits sec
# Daily Ave  2012 07 04 00 00 07   2012 07 05 00 00 07    127.300 Gbits 86400 sec  > 127.299 Gbits day 1.473 Mbits sec

# Robert Cameron
# January 2013

# usage: ./xssr.pl < ssr.history

while (<>) {
    next unless (/Daily Ave/);
    @f = split;
    $t0 = "$f[2]-$f[3]-$f[4]/$f[5]:$f[6]:$f[7]";
    $t1 = "$f[8]-$f[9]-$f[10]/$f[11]:$f[12]:$f[13]";
    if ($pt1) { print "$0: Unexpected time jump from $pt1 to $t0\n" unless ($pt1 eq $t0) };
    $pt1 = $t1;
}
