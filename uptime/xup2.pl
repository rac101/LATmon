#!/usr/local/bin/perl -w

# check time continuity in the file "tup.out"

# Robert Cameron
# October 2012

use Time::Local;
use Time::JulianDay;

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

# 4 = 5 + 6 + 7 + 8 + 9 + 11 + 13 + 15 + 16 + 17

# usage: ./xup.pl < tup.out

# start of an example line from tup.out
#  2012-10-06 23:59:55.140073 2012-10-08 00:00:04.617595 86409.400274

while (<>) {
    next unless (/^ 20/);
    @f = split; 
    ($y,$mon,$d) = split("-",$f[0]);
    ($h,$m,$s) = split(":",$f[1]);
#    $jd1 = julian_day($y,$mon,$d) + $h/24.0 + $m/1440.0 + $s/86400.0;
    $jd1s = `date -u --date="$f[0] $f[1]" +"%s"`;
    chomp $jd1s;
    $jd1 = $jd1s/86400.0;
    ($y,$mon,$d) = split("-",$f[2]); 
    ($h,$m,$s) = split(":",$f[3]);
#    $jd2 = julian_day($y,$mon,$d) + $h/24.0 + $m/1440.0 + $s/86400.0;
    $jd2s = `date -u --date="$f[2] $f[3]" +"%s"`;
    chomp $jd2s;
    $jd2 = $jd2s/86400.0;
#    $dt = $f[4];
#    $dd = $jd2 - $jd1;
#    $ds = $jd2s - $jd1s;
#    print STDERR "$f[0] $f[1]: JD1 = $jd1, JD1S = $jd1s; $f[2] $f[3]: JD2 = $jd2, JD2S = $jd2s; DayDiff = $dd; SecDiff = $ds\n";
    if (abs($jd2 - $jd1 - 1) > 0.0002) { print "$0: Start $f[0] $f[1] and stop $f[2] $f[3] are not 1 day apart\n"};
    if ($jd02 && abs($jd02 - $jd1) > 0.0002) { print "$0: Time gap found between previous ending time $t02 and starting time $f[0] $f[1]\n" };
    $ttot1 = $f[5] + $f[6] + $f[7] + $f[8] + $f[9] + $f[11] + $f[13] + $f[15] + $f[16] + $f[17];
    $ttot2 = $ttot1 + $f[10] + $f[12] + $f[14];
#    $ttot3 = $ttot1 + $f[23] + $f[24] + $f[25] + $f[26];
    if (abs($f[4] - $ttot1) > 100) { print "$0: tot time $f[4] != $ttot1 sum of LIM mode times at $f[0] $f[1]\n" };
    if (abs($f[4] - $ttot2) > 100) { print "$0: tot time $f[4] != $ttot2 sum of LIM mode + wrong-in-SAA times at $f[0] $f[1]\n" };
#    if (abs($f[4] - $ttot3) > 100) { print "$0: tot time $f[4] != sum3 $ttot3 at $f[0] $f[1]\n" };
    $jd02 = $jd2;
    $t02 = "$f[2] $f[3]";
}
