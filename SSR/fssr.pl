#!/usr/bin/perl -w

# simplify history of daily SSR Usage

# typical lines from ssr.history
# Daily Ave  2012 06 16 23 59 58   2012 06 17 23 59 58    126.620 Gbits 86399 sec  > 126.620 Gbits day 1.466 Mbits sec
# Daily Ave  2012 06 17 23 59 58   2012 06 18 23 59 58    128.105 Gbits 86399 sec  > 128.106 Gbits day 1.483 Mbits sec
# Daily Ave  2012 07 03 00 00 07   2012 07 04 00 00 07    128.197 Gbits 86399 sec  > 128.197 Gbits day 1.484 Mbits sec
# Daily Ave  2012 07 04 00 00 07   2012 07 05 00 00 07    127.300 Gbits 86400 sec  > 127.299 Gbits day 1.473 Mbits sec

# Robert Cameron
# June 2018

# usage: ./fssr.pl < ssr.history > ssr.simple

use Time::Piece ();
use Time::Seconds;

#my $numdays = 1;

while (<>) {
    next unless (/Daily Ave/);
    @f = split;
#    print STDERR "$_" if ($f[5] > 1 and $f[5] < 23);
    $date = "$f[2]-$f[3]-$f[4]";
    $dt = Time::Piece->strptime( $date, '%F');
#    $dt += ONE_DAY * $numdays if ($f[5] > 12);
    $dt += ONE_DAY if ($f[5] > 12);
    $date = $dt->strftime('%F');
#    $ymd = `date --date="$ymd + 1 day" +"%F"` if ($f[5] > 12);
#    chomp $ymd;
    print "$date $f[-6]\n";
}
