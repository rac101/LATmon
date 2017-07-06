#!/usr/local/bin/perl -w

# check SAA reports against previous the previous report
# look for SAA transits that appear or disappear in the newer report
# NOTE: this script runs through my private archive of reports

# Robert Cameron
# January 2015

# usage: ./xasaax.pl

$maxtransit = 999; # the limit to the number of transits to check

# path to my archive of SAA reports 
$wdir = "/u/gl/rac/LATmetrics/saa/reports";

# read the archived report names into a sorted array
@rep = `cd $wdir; ls -1 L*`;
@srep = sort (@rep);

# compare successive reports
# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

for $i (1..$#srep) {
#for $i (405..405) {
    $rep1 = $srep[$i-1];
    $rep2 = $srep[$i];
    chomp $rep1;
    chomp $rep2;
    @r1 = `cat $wdir/$rep1`;
    @r2 = `cat $wdir/$rep2`;
    $#r1 = $maxtransit if ($#r1 > $maxtransit);
    $#r2 = $maxtransit if ($#r2 > $maxtransit);
    %en1 = ();
    @en1  = ();
    %en2 = ();
    @en2  = ();
    foreach (@r1) {
	next unless (/\/20/);
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	push @en1,$f[2];
	$en1{$f[2]} = "$f[0] $f[1] $f[-1]";
    }
    foreach (@r2) {
	next unless (/\/20/);
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	push @en2,$f[2];
	$en2{$f[2]} = "$f[0] $f[1] $f[-1]";
    }
    next unless (@en1 and @en2);
    $first = ($en1[0] > $en2[0])? $en1[0] : $en2[0];
    $last = ($en1[-1] > $en2[-1])? $en2[-1] : $en1[-1];
    while (@en1 and ($en1[0] < $first)) { shift @en1 };
    while (@en2 and ($en2[0] < $first)) { shift @en2 };
    while (@en1 and ($en1[-1] > $last)) { pop @en1 };
    while (@en2 and ($en2[-1] > $last)) { pop @en2 };
#    next unless (@en1 or @en2);
    $n1 = scalar(@en1);
    $n2 = scalar(@en2);
    print "checking $rep2 wrt $rep1: $rep2 has $n2 orbits overlapping with $n1 orbits for $rep1\n";
    foreach $o (@en1) { print "\t$rep2 wrt $rep1 is missing a transit at orbit $o at $en1{$o}\n" unless ($en2{$o}) };
    foreach $o (@en2) { print "\t$rep1 wrt $rep2 is missing a transit at orbit $o at $en2{$o}\n" unless ($en1{$o}) };
}
