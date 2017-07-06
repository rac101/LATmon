#!/usr/local/bin/perl -w

# check time continuity of history of daily trigger count

# typical lines from trigrate.jana
# Daily Ave  2013 01 07 23 59 57   2013 01 09 00 00 06 164438750 triggers / 86408 sec  > 1903.0 Hz/day 1.903 kHz/day
# Daily Ave  2013 01 09 00 00 06   2013 01 10 00 00 16 163989806 triggers / 86410 sec  > 1897.8 Hz/day 1.898 kHz/day

# Robert Cameron
# January 2013

# usage: ./xtrig.pl < trigrate.jana

use Time::Local;

while (<>) {
    next unless (/Daily Ave/);
    @f = split;
    $st0 = "$f[2]-$f[3]-$f[4]/$f[5]:$f[6]:$f[7]";
    $st1 = "$f[8]-$f[9]-$f[10]/$f[11]:$f[12]:$f[13]";
    $t0 = timegm($f[7],$f[6],$f[5],$f[4],$f[3]-1,$f[2]);
    $t1 = timegm($f[13],$f[12],$f[11],$f[10],$f[9]-1,$f[8]);
    if ($pt1) { print "$0: Unexpected time jump from $pst1 to $st0\n" unless (abs($pt1-$t0) < 30) };
    $pt1 = $t1;
    $pst1 = $st1;
}
