#!/usr/local/bin/perl -w

# get the latest GLAST TDRSS Forecast Schedule file

# Robert Cameron
# May 2016

# usage: ./getTDRSS.pl > TDRSSschedule.yaml

use File::Basename;
#$sn = basename($0);

# path to the FastCopy archive 
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# look for most recent GLAST TDRSS Forecast Schedule files in the FastCopy archive
$i = -1;
until (@r) {
    $i++;
    $day = `date -u --date="$i days ago" +"%Y/%m/%j.*"`;
    chomp $day;
    @r = `find $fcdir/$day -name 'OPS_NCC_2525_asf_20*'`;
}
@sr = sort(@r);
$rep = $sr[-1];
#@f = split("fcopy",$rep);
#print STDERR "$sn: most recent TDRSS Forecast Schedule is:\n $f[-1]\n";
@rep = `cat $rep`;

# convert to YAML format for output

foreach (@rep) { 
    next unless (/(SCHEDULEDEVENT|TDRS|EVENTSTART|EVENTSTOP)/);
    next if (/END/);
    s/(=|$)/ : /;
    print $_;
}
