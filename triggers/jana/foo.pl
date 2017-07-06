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
    unless (/Daily Ave/) { print $_; next };
    @f = split ("z",$_);
    print "$f[0]z\n";
}
