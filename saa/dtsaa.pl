#!/usr/local/bin/perl -w

# pair SAA reports with the previous report and get the number of days between them
# NOTE: this script runs through my private archive of reports

# Robert Cameron
# January 2015

# usage: ./dtsaa.pl

# path to my archive of SAA reports 
$wdir = "/u/gl/rac/LATmetrics/saa/reports";

# SAA report file names have the format: L2014342SAA.02
# read the archived report names into a sorted array
@rep = `cd $wdir; ls -1 L20*SAA*`;
@srep = sort (@rep);

@ylen = (366,365,365,365);

for $i (1..$#srep) {
    $rep1 = $srep[$i-1];
    $rep2 = $srep[$i];
    chomp $rep1;
    chomp $rep2;
    $rep1 =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $y1 = $1;
    $d1 = $2;
    $rep2 =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $y2 = $1;
    $d2 = $2;
    $leap = $y1 % 4;
    $extra = ($y1 == $y2)? 0 : $ylen[$leap];
    $dd = $d2 - $d1 + $extra;
    print "$rep2 $rep1 ";
    print "$y2 $d2 $dd\n";
}

