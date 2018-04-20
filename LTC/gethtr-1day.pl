#!/usr/local/bin/perl -w

# get daily LTC HTR state duty cycle
# here is the format of the MnemRet.py command:
# MnemRet.py -b '-1 days' -e '2012-06-30 00:00:00' LTCnnHTRSTATE
#
# which produces the output:
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC00HTRSTATE  0 (  0)
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC06HTRSTATE  0 (  0)
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC07HTRSTATE  0 (  0)

# output to STDOUT (htr.history) will be
# YYYY-MM-DD "HTR #1 samples #all samples" for each HTR

# Robert Cameron
# February 2014

# usage: ./gethtr-1day.pl >> htr.history

# first, find the most recent good results in htr.history

#use File::Basename;
use Try::Tiny;
#$sn = basename($0);

use strict 'subs';
use strict 'refs';

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 300;
    main();
    alarm 10;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: timed out\n";
}
finally {
#    print "done\n";
};

sub main {

    $htrfile = "/u/gl/rac/LATmetrics/LTC/htr.history";
    @tail = `tail $htrfile`;

    foreach (@tail) { $last = $_ if (/^20/) };
    die "$0: No heater history data found at tail of $htrfile\n" unless ($last);

    @f = split(' ',$last);
    $taildate = `date --date="$f[0] + 1 day" +"%F"`;
    chomp $taildate;
    $taildate_s = `date --date="$taildate" +"%s"`;

# bring the file "up to date", i.e. the day before yesterday

    $yesterday = `date --date="2 days ago" +"%F"`;
    chomp $yesterday;
    $yesterday_s = `date --date="$yesterday" +"%s"`;
    
    $numdays = int(($yesterday_s - $taildate_s)/86400);

    if ($numdays > 1) { print STDERR "$0: processing $numdays days from $taildate to $yesterday\n" };
#print STDERR "$0: processing $numdays days from $taildate to $yesterday\n";
#die "$0: $htrfile is up to date. Ending.\n" unless ($numdays > 0);
    exit unless ($numdays > 0);

    $htrs = '';
    @key = ('00','06','07','01','02','03','04','05','08','09','10','11');
    foreach (@key) {$htrs .= " LTC".$_."HTRSTATE" };

    foreach (0..$numdays) {
	$date = `date --date="$taildate + $_ days" +"%F"`;
	chomp $date;
	$cmd = "MnemRet.py -b '$date 00:00:00' -e '+1 days' $htrs";
#    print STDERR "$0: run: $cmd\n";
	@htr = `$cmd`;

# send results to STDOUT
	
	%on = ('00',0,'06',0,'07',0);
	%ct = %on;

	foreach (@htr) {
	    next unless (/^VAL/);
	    @f = split;
	    $h = $f[4];
	    $h =~ s/LTC//;
	    $h =~ s/HTRSTATE//;
	    $ct{$h} += 1;
	    $on{$h} += $f[5];
	}
	$t = '';
	foreach (@key) { $t .= "\t$_\t$ct{$_}\t$on{$_}" if ($_ eq '00' or $_ eq '06' or $_ eq '07' or $on{$_}) };
	print "$date$t\n";
    }   # end of days for loop
}   # end of main sub
