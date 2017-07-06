#!/usr/local/bin/perl

# analyse and summarize daily uptime numbers collected using Jana's Uptime.py script

# Robert Cameron
# May 2012

use Time::Local;

# usage: ./atup.pl

#t0 t1 Total TERMINAL QUIESCENT CALIBRATION DIAGNOSTIC PHYSICS PHYSICS_SAA TOO TOO_SAA ARR ARR_SAA HOLD BOOT OFF SAA IDLE RUNNING STOPPING UNKNOWN IDLE RUNNING STOPPING UNKNOWN 
#                                                                    LIM Mode Summary-----------------'
# 2008-07-30 23:59:55.340094 2008-08-01 00:00:04.340101 86408.000006 89.323223 19990.811864 0 0 41980.099320 0 0 0 180.540356 0 0 0 0 34375.260756 20342.698928 41959.864189 20.233290 0 62322.800066 0 0 0 
# 2008-07-31 23:59:55.340101 2008-08-02 00:00:04.340073 86407.999970 0 0 0 0 0 0 0 0 0 0 0 0 0 86407.999970 0 0 0 0 0 0 0 0 

# time fields: 
#  4 total
#  5 terminal
#  6 quiescent
#  7 calibration
#  8 diagnostic
#  9 physics
# 10 physics in SAA
# 11 ToO
# 12 ToO in SAA
# 13 ARR
# 14 ARR in SAA
# 15 hold
# 16 boot
# 17 off (how is that known from telemetry?)
# 18 SAA mode
# 19 LPA idle
# 20 LPA running
# 21 LPA stopping 
# 22 LPA unknown
# 23 LCI idle 
# 24 LCI running
# 25 LCI stopping
# 26 LCI unknown

open( TUP, "tup.out" ) or die "$0: Cannot open input file 'tup.out'\n";
while (<TUP>) {
    next unless /20/;
    next if /2008-07/;
    @f = split;
    if ($f[1] =~ /^23:5/) {
	($year,$mon,$day) = split(/-/,$f[0]);
#	print "\n$f[0] $f[1] year $year month $mon day $day\n";
	$time = timegm(0,0,0,$day,$mon-1,$year-1900);
	($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = gmtime($time + 86400 + 3600);
	$f[0] = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$day;
	$f[1] = "";
    }
    @k = @f;
    $f[1] =~ s/\..*//;
    $f[3] =~ s/\..*//;
    $k[4] = sprintf "%4.1f",$k[4]/1000;
    for $i (5..26) { $k[$i] = sprintf "%2d", $k[$i]/1000 };
    print "$f[0] $f[1] $k[4] $k[5] $k[6] $k[7] $k[8] $k[9] $k[10] $k[11] $k[12] $k[13] $k[14] $k[15] $k[16] $k[17] $k[18] $k[19] $k[20] $k[21] $k[22] $k[23] $k[24] $k[25] $k[26]\n";
#    print "$f[0] $f[1]: total time is small: int($tot)\n" if ($tot < 86401);
#    print "$t00 $t01: non-zero Off time found: $off\n" if ($off);
#    print "$t00 $t01: LAT might be off or safed due to large SAA time: $saa\n" if ($saa > 18000);
#    print "$t00 $t01: LAT might be off or safed due to small Physics time: $phy\n" if ($phy < 58000);
}
