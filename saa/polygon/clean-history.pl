#!/usr/local/bin/perl -w

# remove duplicate records in history of Fermi LAT on-board SAA polygon vertex coordinates

# archive lines begin with: 
#"2017-04-18 23:09:54.540072",1492556994.540072,

# use the linear Unix seconds value

# input from STDIN

# Robert Cameron
# December 2017

# usage: ./clean-history.pl < history.new.poly

# read in the history file one line at a time
# and only output new records

$prevpoly = '';
while (<>) {
    ($junk,$junk,$junk,$newpoly) = split(' ',$_,4);
    print $_ if ($newpoly ne $prevpoly);
    $prevpoly = $newpoly;
}
