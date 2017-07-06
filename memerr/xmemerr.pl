#!/usr/local/bin/perl -w

# check if memory errors have matching timestamps
# and also check if any days are missing SAA data
# and also check if any days have 9999 pseudo-SAA data
# and also check if any days have been missed
# and also check for long time intervals between errors

#Usage: > ./xmemerr.pl < geosaa.out

use Time::JulianDay;

#input format
#EPU1: 2012-04-22 18:21:41.784301 (1335118901.784301)  Address:   62151696 (0x03b45c10)  Type: 4 (Correctable multi-bit error) -25.944944 -23.729332 1
#EPU0: 2012-04-22 18:21:50.934978 (1335118910.934978)  Address:   99947224 (0x05f512d8)  Type: 3 (Correctable single-bit error) -25.376673 -23.628370 1
# SIU: 2012-04-22 20:02:09.423836 (1335124929.423836)  Address:  131599768 (0x07d80d98)  Type: 4 (Correctable multi-bit error) -31.731960 -19.124795 1
#EPU1: 2012-04-22 21:46:49.660921 (1335131209.660921)  Address:   94636400 (0x05a40970)  Type: 3 (Correctable single-bit error) -25.210983 -6.104414 1

#@doy = ([0,0,31,60,91,121,152,182,213,244,274,305,335],
#        [0,0,31,59,90,120,151,181,212,243,273,304,334],
#        [0,0,31,59,90,120,151,181,212,243,273,304,334],
#        [0,0,31,59,90,120,151,181,212,243,273,304,334]);
#@yom = (-163);    # linear Day Of Mission 
#foreach (1..99) {
#    $n = 365;
#    if (($_ % 4) == 1) { $n = 366 };
#    push @yom,$yom[$_-1]+$n;
#}

while (<>) {
    next unless (/U/);
    @f = split;
    $nf = scalar(@f); 
    if ($nf != 15) { print "$0: incorrect number of fields, $nf, found on record at $f[0] $f[1] $f[2]\n" };
    if ($f[-1] == -9999 or $f[-2] == -9999 or $f[-3] == -9999) { print "$0: invalid SAA data found on record at $f[0] $f[1] $f[2]: $f[-3] $f[-2] $f[-1]\n" };
    chop $f[3];
    ($t = $f[3]) =~ s/\(//;
    ($y,$m,$d) = split(/-/,$f[1]);
    $jd = julian_day($y, $m, $d);
#    $k = "$f[0] $f[1] $f[2] $f[5]";
    $k = "$f[0] $f[1] $f[2]";
    if ($h{$k}) { 
#	print "$0: Duplicate found\n $h{$k} $_\n";
	print "$0: Bad memory location difference: $k: $h5{$k} $f[5]\n" if (($f[5]-$h5{$k}) <= 0);
    }
    if ($pjd) { 
	$dt = int($t - $pt);
	$dd = $jd - $pjd;
	print "$0: Unexpected day jump, from $pf1 to $f[1]\n" unless (($dd == 0) or ($dd == 1));
	print "$0: Large time jump of $dt seconds, from $pt (on $pf1) to $t (on $f[1])\n" if ($dt > 70000);
    }
    $h{$k} = $_;
    $h5{$k} = $f[5];
    $pjd = $jd;
    $pf1 = $f[1];
    $pt = $t;
}
