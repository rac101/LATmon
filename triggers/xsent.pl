#!/usr/local/bin/perl -w

# check time continuity of history of daily GEM SENT count

# typical lines from gem.sent
#2011-05-01 13 27 28.943126 800780824
#2011-05-02 13 27 26.943128 965220442
#2011-05-03 13 27 23.943135 1130136021

# Robert Cameron
# April 2013

# usage: ./xsent.pl < gem.sent

use Time::Local;

while (<>) {
    next unless (/^20/);
    @f = split;
    ($y,$m,$d) = split("-",$f[0]);
    $ts = "$f[0]/$f[1]:$f[2]:$f[3]";
    $tt = timegm($f[3],$f[2],$f[1],$d,$m-1,$y);
    if ($ptt) { print "$0: Unexpected time jump from $pts to $ts\n" unless (abs($tt-$ptt-86400) < 30) };
    $ptt = $tt;
    $pts = $ts;
}
