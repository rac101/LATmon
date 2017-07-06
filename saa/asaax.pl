#!/usr/local/bin/perl -w

# check SAA reports
# 1. check if SAA entries are ever in the same orbit number.
# 2. check if SAA exits are ever in the same orbit number.
# NOTE: this script runs through my private archive of reports

# Robert Cameron
# January 2015

# usage: ./asaax.pl SAA.reports

# path to my archive of SAA reports 
$wdir = "/u/gl/rac/LATmetrics/saa/reports";

# read the archived report names into a sorted array
@rep = `cd $wdir; ls -1 L*`;
@srep = sort (@rep);

# compare consecutive reports
# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

#for $i (1..$#srep) {
for $i (100..100) {
    $rep1 = $srep[$i-1];
    $rep2 = $srep[$i];
    chomp $rep1;
    chomp $rep2;
    @r1 = `cat $wdir/$rep1`;
    @r2 = `cat $wdir/$rep2`;
    @s1 = @r1[151..200];
    %en = ();
    %ex = ();
    $y0 = 0;
    foreach (@s1) {
	next unless (/\/20/);
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
#	print STDERR "$f[0] $f[1] $f[2] $en{$f[2]}\n";
#	$iorb = $f[2];
#	print STDERR "$f[0] $f[1] $f[2] $en{$f[2]} $en{iorb}\n";
#	print STDERR "$0: in report $rep1, a repeat SAA transit at $f[1] or $en{$f[2]} or $en{iorb} for orbit number $f[2] or $iorb\n" if ($en{$f[2]});
	print STDERR "$0: in report $rep1, a repeat transit at $f[1] or $en{$f[2]} for orbit number $f[2]\n" if ($en{$f[2]});
	($doy, $y) = split('/',$f[0]);
	unless ($y0) {
	    $y0 = $y;
	    $extradays = ($y % 4)? 365 : 366;
	}
	$doy += $extradays unless ($y == $y0);
	($h,$m,$s) = split(':',$f[1]);
#	$t = $doy*86400 + $h*3600 + $m*60 + $s;
	$t = $h*3600 + $m*60 + $s;
#	print STDERR $en{iorb}, " and $f[1], and $t, for orbit $iorb\n" if ($en{iorb});
	$en{$f[2]} = $t;
	($doy, $y) = split('/',$f[3]);
	$doy += $extradays unless ($y == $y0);
	($h,$m,$s) = split(':',$f[4]);
	$ex{$f[2]} = $doy*86400 + $h*3600 + $m*60 + $s;
    }
    $idx1 = $i-1;
    $idx2 = $i;
    $trans = 0;
    $match = 0;
    $dtmin = 999999999.0;
    $dtmax = 0-$dtmin;
    $dtavg = $dtmax;
#    $dtmed = $dtmax;
    foreach (@r2) {
	next unless (/\/20/);
	$trans++;
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
#	$iorb = $f[2];
	next unless ($en{$f[2]});
	$match++;
	($doy, $y) = split('/',$f[0]);
	$doy += $extradays unless ($y == $y0);
	($h,$m,$s) = split(':',$f[1]);
	$ten = $doy*86400 + $h*3600 + $m*60 + $s;
	$dt = $ten - $en{$f[2]}; 
	$dtmin = $dt if ($dt < $dtmin);
	if ($dt > $dtmax) {$dtmax = $dt; print "entry: $f[0] $f[1] $f[2] $en{$f[2]}, $dt\n"};
	$dtavg += $dt;
	($doy, $y) = split('/',$f[3]);
	$doy += $extradays unless ($y == $y0);
	($h,$m,$s) = split(':',$f[4]);
	$tex = $doy*86400 + $h*3600 + $m*60 + $s;
	$dt = $tex - $ex{$f[2]}; 
	$dtmin = $dt if ($dt < $dtmin);
	if ($dt > $dtmax) {$dtmax = $dt; print "exit: $f[3] $f[4] $f[2] $ex{$f[2]}, $dt\n"};
#	$dtmax = $dt if ($dt > $dtmax);
	$dtavg += $dt;	
    }
    $dtavg /= $match*2;
    print STDERR "$0: $rep2 differs from $rep1 by up to $dtmax seconds\n" if ($dtmax > 30); 
    print "$idx2 $rep2, $trans lines, wrt $idx1 $rep1: min dT = $dtmin, max dT = $dtmax, avg dT = $dtavg, from $match SAAs\n";
}

