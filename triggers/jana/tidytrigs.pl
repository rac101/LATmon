#!/usr/local/bin/perl -w

# tidy the file trigrate.jana into a single format
#
# typical lines from trigrate.jana
# Daily Ave (2012-06-17 23:59:57 - 2012-06-19 00:00:05) :        164526066 triggers / 86398 sec ->      1904.3 Hz
# Daily Ave  2012 06 18 23 59 57   2012 06 20 00 00 03           165352890 triggers / 86398 sec  >      1913.9 Hz

# Robert Cameron
# November 2015

# usage: ./tidytrigs.pl < trigrate.jana > trigrate.jana.tidy

# first, find the most recent good results in trigrate.jana

while (<>) { 
    next if (/WARNING/);
    next unless (/Daily Ave/);
    s/[-:\(\)]/ /g;
    s/\s{2,}/ /g;
    @f = split('z',$_);
    print "$f[0]z\n";
}
