#!/usr/local/bin/perl -w

# maintain an up-to-date list of GLAST ephemeris files

# Robert Cameron
# January 2016

# usage: ./findeph0.pl

# path to the FastCopy archive
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# get relevant Year/Month/DOY
foreach $w (300..397) { 
    $date = `date --date="today - $w weeks" +"%Y/%m/%j.*"`;
    chomp $date;
    print "$date  ";

# look for GLAST ephemeris files in the FastCopy archive
    @r = `find $fcdir/$date -name 'GLAST_EPH_20*'`;
    unless (@r) { $r[0] = "gap\n" };
    @sr = sort (@r);
    foreach (reverse(@sr)) { 
	print $_;
	chomp $_;
	`echo "$_" >> EPH.reports`;
    }
}
