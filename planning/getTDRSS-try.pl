#!/usr/local/bin/perl -w

# get the latest GLAST TDRSS Forecast Schedule file
# main code is now wrapped in timeout structure, based on previous runaway example of this script

# Robert Cameron
# May 2016

# usage: ./getTDRSS-try.pl > TDRSSschedule.txt

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

# make day hash, to help linearize contact times
# contact start and stop times are of the form: YYYY/DOY/HH:MM:SS, e.g. 2016/147/18:09:33
# make hash table of cumulative day count keyed by year
# and arrays of years and cumulative day count

    $day0 = 0;
    for $year (2001..2090) {
	push @year,$year;
	push @day0,$day0;
	$day0{$year} = $day0;
	$day0 += 365;
	$day0++ unless ($year % 4);
    }

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

# convert to compact text format for output

    foreach (@rep) { 
	next unless (/(SCHEDULEDEVENT|TDRS|EVENTSTART|EVENTSTOP|DATARATEMAXI)/);
	next if (/END/);
#	s/(=|$)/ : /;
	s/(=|$)/ /;
	s/"//g;
	s/ +/ /g;
	chomp unless (/DATARATEMAXI/);
	if (/DATARATEMAXI/) { 
	    s/40000000/Ku/;
	    s/8000/8k/;
	    s/4000/4k/;
	    s/2000/2k/;
	    s/1000/1k/;
	    print " $hms ";
	}
	$t0 = secs($_) if (/START/);
	if (/STOP/) { 
	    $t1 = secs($_);
	    $dt = $t1 - $t0;
	    $hms = hms($dt);
	}
	s/EVENT//;
	s/SCHEDULED/T/;
	s/DATARATEMAXI//;
	s/TDRS//;
	s/START//;
	s/STOP//;
	print $_;
    }

}

##***************************************************************************
sub hms {
##***************************************************************************

# convert a duration in seconds to formatted HH:MM:SS

    my $dur = shift;
    $hh = sprintf "%02d", $dur / 3600;
    $dur -= $hh*3600;
    $ss = $dur % 60;
    $mm = $dur / 60;
    $hms = sprintf "$hh:%02d:%02d",$mm,$ss;
    return $hms;
}

##***************************************************************************
sub secs {
##***************************************************************************

# convert a formatted TDRSS event time to linear seconds

    my $event = shift;

    $event =~ s/\D/ /g;
    ($y,$doy,$h,$m,$s) = split(' ',$event);
    $sevent = ($day0{$y}+$doy-1)*86400 + $h*3600 + $m*60 + $s;
    return $sevent;
}
