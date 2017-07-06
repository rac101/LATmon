#!/usr/local/bin/perl -w

# reformat output files into a format suitable for plotting in IDL

# Robert Cameron
# January 2015

# usage: ./sinplot.pl
# read from STDIN
# write to STDOUT

@ylen = (366,365,365,365);

# example input line:
#L2014300SAA.03, 588 lines, wrt L2014293SAA.00: 518 matched SAAs: min, max, avg dT = 0.248, 46.668, 10.915
while (<>) {
    next if (/exceeds/);
    chomp;
    s/,//g;
    @f = split;
    $rep2 = $f[0];
    $rep1 = $f[4];
    $ntransits = $f[1];
    $nmatch = $f[5];
    $mindt = $f[-3];
    $maxdt = $f[-2];
    $avgdt = $f[-1];
    $rep2 =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $y2 = $1; 
    $d2 = $2;
    $rep1 =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $y1 = $1; 
    $d1 = $2;
    $leap = $y1 % 4;
    $extra = ($y1 == $y2)? 0 : $ylen[$leap];
    $deldays = $d2 - $d1 + $extra;
    print "$y2 $d2 $deldays $ntransits $nmatch $mindt $maxdt $avgdt\n";
}
