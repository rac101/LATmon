#!/usr/local/bin/perl -w

# copy SAA reports into my own archive

# Robert Cameron
# January 2015

$wdir = "/u/gl/rac/LATmetrics/saa";
@rep = `head -370 $wdir/SAA.reports`;

foreach $r (@rep) {
    chomp $r;
    `cp $r $wdir/reports/`;
}
