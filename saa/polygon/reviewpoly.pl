#!/usr/local/bin/perl -w

# get Fermi LAT on-board SAA polygon vertex coordinates for each day over a range of dates and check against the first day
# when a new polygon is found, that takes over as the comparison baseline

# here is the format of the MnemRet.py command:
# MnemRet.py -e '+20 minutes' -b '2017-04-19 00:00:00' --expr 'VSGSAA1PLONG[01][0-9]' --expr 'VSGSAA1PLAT[01][0-9]' --csv /dev/stdout

# which produces the output:
#TIME,TSTAMP,VSGSAA1PLONG11,VSGSAA1PLONG10,VSGSAA1PLONG12,VSGSAA1PLONG06,VSGSAA1PLONG05,VSGSAA1PLONG02,
#VSGSAA1PLONG08,VSGSAA1PLONG07,VSGSAA1PLONG04,VSGSAA1PLONG03,VSGSAA1PLONG09,VSGSAA1PLONG01,
#VSGSAA1PLAT04,VSGSAA1PLAT05,VSGSAA1PLAT06,VSGSAA1PLAT07,VSGSAA1PLAT01,VSGSAA1PLAT02,
#VSGSAA1PLAT03,VSGSAA1PLAT12,VSGSAA1PLAT10,VSGSAA1PLAT09,VSGSAA1PLAT11,VSGSAA1PLAT08
#"2017-04-18 23:09:54.540072",1492556994.540072,-92.3576278687,-98.7405853271,-86.3746795654,
#-42.2145690918,-36.2145996094,24.2967681885,-93.3340835571,-59.0187149048,-25.9159297943,-18.8183670044,
#-97.7361755371,33.7110290527,5.11406803131,5.12288284302,4.52918481827,0.650709033012,-30.0793151855,
#-22.6869277954,2.40959143639,-30.0062637329,-12.4856929779,-9.8873462677,-21.6962871552,-8.59464359283

# output to STDOUT, on which day(s), if any, the SAA polygon is different from the 

# Robert Cameron
# April 2018

# usage: ./reviewpoly.pl start-date end-date

use File::Basename;
$sn = basename($0);

($d0,$d1) = @ARGV;
$s0 = `date --date="$d0" +"%s"`;
$s1 = `date --date="$d1" +"%s"`;
$dd = sprintf "%.0f",($s1-$s0)/86400;
die "$sn: unusable input dates $d0 and $d1\n" unless ($dd >= 2);
print STDERR "$sn: will check SAA polygons for $dd days\n";

$c = "MnemRet.py -e '+20 minutes' -b '$d0 00:00:00' --expr 'VSGSAA1PLONG[01][0-9]' --expr 'VSGSAA1PLAT[01][0-9]' --csv /dev/stdout";
($hdr,@res) = `$c`;

# Establish the parameter sequence for building the polygon strings from the first readout
chomp $hdr;
die "$sn: first line is not HEADER line\n" unless ($hdr =~ /^TIME/);
@var = split(',',$hdr);
@idx = sort { $var[$a] cmp $var[$b] } 0 .. $#var;
$refpoly = "";

# get the SAA polygon one day at a time
# if the new polygon matches the old polygon, then stay quiet
# if the new polygon does not match the old, then report so and make the new polygon the template

foreach $i (0 .. $dd) {
    $date = `date --date="$d0 + $i days" +"%F"`;
    chomp $date;
    print "$sn: started checking polygons for $date\n";
    $c = "MnemRet.py -e '+20 minutes' -b '$date 00:00:00' --expr 'VSGSAA1PLONG[01][0-9]' --expr 'VSGSAA1PLAT[01][0-9]' --csv /dev/stdout";
    ($hdr,@res) = `$c`;
    foreach (@res) {
	next unless (/20/);
	chomp;
	@val = split(',',$_);
	@sval = @val[@idx];
	$newdate = $sval[0];
#	print "$sn: checking polygon for $newdate\n";
	$poly = join " ",@sval[2..$#sval];
	if ($poly ne $refpoly) {
	    print STDERR "$sn: >>>>>>>> new LAT SAA polygon found at $newdate\n" if ($refpoly);
	    $refpoly = $poly;
	}
    }
}
