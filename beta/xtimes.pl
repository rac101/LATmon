#!/usr/local/bin/perl -w

# check timesteps between lines of the nav files
# 
#2009-01-01 14:00:00 1230818400 -6458615.0 1351647.250 2109914.250 -2213.225 -6877.500 -2323.044
#
# should be 1 hour = 3600 seconds between lines

# Robert Cameron
# September 2013

# usage: ./xtimes.pl nav.YYYY

$sold = 0;
$told = '';
$linecount = 0;
while (<>) {
    $linecount++;
    @f = split;
    $n = scalar(@f);
    if ($n != 9) { print "$0: at line $linecount, incorrect number of values on the line: $n\n" };
    if ($f[2] != $sold+3600 and $told) { print "$0: at line $linecount, invalid time step from $told to $f[0] $f[1] $f[2]\n" };
    $sold = $f[2];
    $told = "$f[0] $f[1] $f[2]";
}
