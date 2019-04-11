#!/usr/local/bin/perl -w

# find N latest SAA reports

# Robert Cameron
# September 2018

# usage: ./findreports.pl
# output goes to STDOUT, and STDERR if necessary

# path to the FastCopy archive of SAA reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# for several recent days' Year/Month/DOY look for recent SAA reports
# check multiple days in case there was some multi-day report ingest problem

foreach $dold (0..16) { 
    $day = `date --date="$dold days ago" +"%Y/%m/%j.*"`;
    chomp $day;
    @r = `find $fcdir/$day -name 'L20*SAA*'`;
    if (@r) {
	print @r;
    }
}
