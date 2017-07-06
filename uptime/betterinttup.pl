#!/usr/local/bin/perl -w

# convert floats to integers in the file "tup.out", and fix the start time, add linear mission day

# Robert Cameron
# March 2014

#usage
#./betterinttup.pl < tup.out > tup.int

use Time::Local;

$fermiMET0 = timegm(0,0,0,1,0,2001);

print "                                                ";
print "|LIM   Cal Dia PiS TO TiS AiS HldBtOf|SAA--|-----LPA-------|--LCI-----|\n";
print "T0               ";
print "Total Term Qui C D Phy   P T T ARR A H B O SAA   Idle  Run Stop ? Idle  R S ?\n";
while (<>) {
    next unless (/20/);
    @f = split;
    $i = 1;
    $i++ if (/#/);
	     ($year,$mon,$mday) = split("-",$f[$i-1]);
	     $mon--;
    ($h,$m,$s) = split(":",$f[$i]);
	     $timeofday = $h*3600 + $m*60 + $s;
	     $timeofday = 0 if (abs($timeofday) < 200);
	     $timeofday = 86400 if (abs($timeofday-86400) < 200);
	     $starttime = timegm(0,0,0,$mday,$mon,$year)+$timeofday+100;
	     $missionday = int(($starttime - $fermiMET0)/86400);
	     ($junk,$junk,$junk,$mday,$mon,$year) = gmtime($starttime);
	     $mon++;
	     $year += 1900;
	     $ymd = sprintf "$year-%02d-%02d",$mon,$mday;
    $s = int($s + 0.5);
    $s = sprintf "%02d",$s;
    $f[$i] = $missionday;
	     $f[$i-1] = $ymd;
	     $i = 3;
    $i++ if (/#/);
    ($h,$m,$s) = split(":",$f[$i]);
    $s = int($s + 0.5);
    $s = sprintf "%02d",$s;
    $f[$i] = "";
	     $f[$i-1] = "";
    $i = 4;
    $i++ if (/#/);
    foreach (@f[$i..$#f]) { $_ = int($_ + 0.5) };
    $out = join(' ',@f);
    print "$out\n";
}
