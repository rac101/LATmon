#!/usr/local/bin/perl -w

# process TLE ephemeris files for Fermi

# Robert Cameron
# October 2013

use Try::Tiny;

use strict 'subs';
use strict 'refs';

#$sn = basename($0);

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 90;
    main();
    alarm 10;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: Try timed out\n";
}
finally {
#    print "done\n";
};

#####################################
sub main {

    $tle_url = "http://celestrak.com/NORAD/elements/science.txt";

# get the recent past TLE data
 
    $tlefile =  "/u/gl/rac/LATmetrics/TLE/TLE.txt";
    @tail = `tail $tlefile`;
    foreach (@tail) {
	$last = $_ if (/^1 33053U 08029A/);
    }
    die "$0: No Fermi TLE data found at tail of $tlefile\n" unless ($last);

# fetch the new TLE data

    @tle = `curl -s $tle_url | grep " 33053"`;
    die "$0: No Fermi TLE data found at $tle_url\n" unless (@tle);

    foreach $i (0..$#tle) { 
	$tle[$i] =~ s/\r//;
	chomp $tle[$i];
	$l1 = $i if ($tle[$i] =~ /^1 33053U 08029A/);
	$l2 = $i if ($tle[$i] =~ /^2 33053  /);
    }
    die "$0: Fermi TLE data not on 2 consective lines\n" unless ($l2=$l1+1);

    $newtle = "$tle[$l1] $tle[$l2]\n";
    print $newtle unless ($newtle eq $last);
}  # end of main sub
