#!/usr/local/bin/perl -w

# get current Fermi LAT on-board SAA polygon vertex coordinates and append to archive
# do this weekly, by cron, to check if FOT is ~monthly doing an update

# here is the format of the MnemRet.py command:
# MnemRet.py -b '-1 hour' -e '2017-04-19 00:00:00' --expr 'VSGSAA1PLONG[01][0-9]' --expr 'VSGSAA1PLAT[01][0-9]' --csv /dev/stdout

# which produces the output:

# input from STDIN

# output to STDOUT = ARCHIVE will be
# YYYY MM DD DOY HH MM SS.ssssss unix-time MET polygon LAT and LONG values in alphabetical order of mnemonic

# Robert Cameron
# May 2017

# usage: ./getpoly.pl >> daily-history.poly

$t = `date -dlast-thursday +"%F 07:00:00"`;
chomp $t;

$c = "MnemRet.py -b '-25 minutes' -e '$t' --expr 'VSGSAA1PLONG[01][0-9]' --expr 'VSGSAA1PLAT[01][0-9]' --csv /dev/stdout";

#print "$c\n";
($hdr,@res) = `$c`;

#print $hdr;
#print "then....\n";
#print @res;

chomp $hdr;
die "$0: first line is not HEADER line\n" unless ($hdr =~ /^TIME/);
@var = split(',',$hdr);
@idx = sort { $var[$a] cmp $var[$b] } 0 .. $#var;

# read in the data one line at a time

$standard = "";
foreach (@res) {
    next unless (/20/);
    chomp;
    @val = split(',',$_);
    @sval = @val[@idx];
    $line = join " ",@sval;
    $tline = join " ",@sval[2..$#sval];
    if ($tline ne $standard) {
	print "$line\n";
	$standard = $tline;
    }
}
