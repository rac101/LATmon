#!/usr/local/bin/perl -w

# process TLE ephemeris files for Fermi

# Robert Cameron
# October 2013

$tle_url = "http://celestrak.com/NORAD/elements/science.txt";

chdir "/nfs/farm/g/glast/u55/rac/LATmetrics/TLE";

# fetch the TLE data

@tle = `/usr/bin/curl $tle_url | grep " 33053"`;
die scalar(gmtime)."$0: No TLE data found in $tle_url\n" unless (@tle);

foreach $i (0..$#tle) { 
    $tle[$i] =~ s/\r//;
    $l1 = $i if ($tle[$i] =~ /^1 33053U 08029A/);
    $l2 = $i if ($tle[$i] =~ /^2 33053  /);
}
die "$0: Fermi TLE data not on consective lines at $tle_url\n" unless ($l2=$l1+1);

$o1 = $tle[$l1];
$o2 = $tle[$l2];
chomp($o1);

open (CF, ">>TLE.txt") or die scalar(gmtime)." $0: $!\n";
print CF "$o1 $o2";
