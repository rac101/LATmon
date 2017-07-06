#!/usr/local/bin/perl -w

# get the latest GLAST TDRSS Forecast Schedule file
# main code is now wrapped in timeout structure, based on previous runaway example of this script

# Robert Cameron
# May 2016

# usage: ./getTDRSS-try.pl > TDRSSschedule.yaml

use File::Basename;
use Try::Tiny;
#$sn = basename($0);

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 15;
    main();
    alarm 0;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: timed out\n";
}
finally {
#    print "done\n";
};

sub main {

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
	next unless (/(SCHEDULEDEVENT|TDRS|EVENTSTART|EVENTSTOP|DATARATEMAXI)/);
	next if (/END/);
#	s/(=|$)/ : /;
	s/(=|$)/ /;
	s/"//g;
	chomp unless (/DATA/);
	s/EVENT//;
	s/SCHEDULED/T/;
	s/DATARATEMAXI/RATE/;
	print $_;
    }

}
