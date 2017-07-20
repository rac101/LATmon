#!/usr/local/bin/perl -w

# get Fermi LAT on-board SAA polygon vertex coordinates and check against archive
# do this weekly, by cron, to check if FOT is ~monthly doing an update

# here is the format of the MnemRet.py command:
# MnemRet.py -b '-1 hour' -e '2017-04-19 00:00:00' --expr 'VSGSAA1PLONG[01][0-9]' --expr 'VSGSAA1PLAT[01][0-9]' --csv /dev/stdout

# which produces the output:
#TIME,TSTAMP,VSGSAA1PLONG11,VSGSAA1PLONG10,VSGSAA1PLONG12,VSGSAA1PLONG06,VSGSAA1PLONG05,VSGSAA1PLONG02,
#VSGSAA1PLONG08,VSGSAA1PLONG07,VSGSAA1PLONG04,VSGSAA1PLONG03,VSGSAA1PLONG09,VSGSAA1PLONG01,
#VSGSAA1PLAT04,VSGSAA1PLAT05,VSGSAA1PLAT06,VSGSAA1PLAT07,VSGSAA1PLAT01,VSGSAA1PLAT02,
#VSGSAA1PLAT03,VSGSAA1PLAT12,VSGSAA1PLAT10,VSGSAA1PLAT09,VSGSAA1PLAT11,VSGSAA1PLAT08
#"2017-04-18 23:09:54.540072",1492556994.540072,-92.3576278687,-98.7405853271,-86.3746795654,
#-42.2145690918,-36.2145996094,24.2967681885,-93.3340835571,-59.0187149048,-25.9159297943,-18.8183670044,
#-97.7361755371,33.7110290527,5.11406803131,5.12288284302,4.52918481827,0.650709033012,-30.0793151855,
#-22.6869277954,2.40959143639,-30.0062637329,-12.4856929779,-9.8873462677,-21.6962871552,-8.59464359283

# input from STDIN

# output to STDOUT = ARCHIVE will be
# YYYY MM DD DOY HH MM SS.ssssss unix-time MET polygon LAT and LONG values in alphabetical order of mnemonic

# expect to run this script once per day
# report to STDERR when there is an update to the polygon
# also, report to STDERR only one day per week. Do NOT report the polygon age every day.

# Robert Cameron
# July 2017

# usage: ./agepoly.pl history.new.poly

use File::Basename;
$sn = basename($0);

# get previous polygon

open (HF, $ARGV[0]) or die "$0: Cannot open polygon History File\n";

@lines = <HF>;

chomp $lines[-1];
($junk,$junk,$oldutc,$oldpoly) = split(' ',$lines[-1],4);

# get current polygon

$t = `date -dyesterday +"%F 00:25:00=%u"`;
chomp $t;
($date,$dow) = split("=",$t);

$c = "MnemRet.py -b '-25 minutes' -e '$date' --expr 'VSGSAA1PLONG[01][0-9]' --expr 'VSGSAA1PLAT[01][0-9]' --csv /dev/stdout";

($hdr,@res) = `$c`;

chomp $hdr;
die "$0: first line is not HEADER line\n" unless ($hdr =~ /^TIME/);
@var = split(',',$hdr);
@idx = sort { $var[$a] cmp $var[$b] } 0 .. $#var;

# read in the data one line at a time
# if the new polygon matches the old polygon, then report the time difference to STDERR
# if the new polygon does not match the old, then report so and add the new line to the history.new file

foreach (@res) {
    next unless (/20/);
    chomp;
    @val = split(',',$_);
    @sval = @val[@idx];
    $newdate = $sval[0];
    $newutc = $sval[1];
    $ddays = sprintf "%.1f",($newutc - $oldutc)/86400.0;
    $line = join " ",@sval;
    $newpoly = join " ",@sval[2..$#sval];
    if ($newpoly eq $oldpoly and $dow == 4) {
	print STDERR "$sn: LAT SAA polygon is $ddays days old at $newdate\n";
    }
    else {
	print HF "$line\n";
	print STDERR "$sn: new LAT SAA polygon added to history file at $newdate\n";
	$oldpoly = $newpoly;
	$oldutc = $newutc;
    }
}
close (HF);
