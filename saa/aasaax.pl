#!/usr/local/bin/perl -w

# check SAA reports against previous the previous report
# NOTE: this script runs through my private archive of reports

# Robert Cameron
# January 2015

# usage: ./aasaax.pl

# path to my archive of SAA reports 
$wdir = "/u/gl/rac/LATmetrics/saa/reports";

# read the archived report names into a sorted array
@rep = `cd $wdir; ls -1 L*`;
@srep = sort (@rep);

# compare consecutive reports
# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

for $i (1..$#srep) {
#for $i (100..100) {
    $rep1 = $srep[$i-1];
    $rep2 = $srep[$i];
    chomp $rep1;
    chomp $rep2;
    print "$0: begin comparing times of SAA transits in $rep2 relative to equivalent times in $rep1\n"; 
    @r1 = `cat $wdir/$rep1`;
    @r2 = `cat $wdir/$rep2`;
    %en = ();
    %ex = ();
    foreach (@r1) {
	next unless (/\/20/);
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	print STDERR "$0: in report $rep1, a repeat transit at $f[1] for orbit number $f[2]\n" if ($en{$f[2]});
	($h,$m,$s) = split(':',$f[1]);
	$en{$f[2]} = sprintf "%.3f",$h*3600 + $m*60 + $s;
	($h,$m,$s) = split(':',$f[4]);
	$ex{$f[2]} = sprintf "%.3f",$h*3600 + $m*60 + $s;
    }
    $idx1 = $i-1;
    $idx2 = $i;
    $trans = 0;
    $match = 0;
    $dtmin = 999999999.0;
    $dtmax = 0-$dtmin;
    $dtavg = 0;
    foreach (@r2) {
	next unless (/\/20/);
	$trans++;
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	next unless ($en{$f[2]});
	$match++;
	($h,$m,$s) = split(':',$f[1]);
	$ten = $h*3600 + $m*60 + $s;
	$dt = sprintf "%.3f",$ten - $en{$f[2]}; 
	if ($dt < $dtmin and abs($dt) < 9000) { $dtmin = $dt; print "SAA entry: $f[0] $f[1] $f[2] $en{$f[2]}, new dT min = $dt\n"};
	if ($dt > $dtmax and abs($dt) < 9000) { $dtmax = $dt; print "SAA entry: $f[0] $f[1] $f[2] $en{$f[2]}, new dT max = $dt\n"};
#	$dtmin = $dt if ($dt < $dtmin and abs($dt) < 9000);
#	$dtmax = $dt if ($dt > $dtmax and abs($dt) < 9000);
#	if ($dt > $dtmax) {$dtmax = $dt; print "entry: $f[0] $f[1] $f[2] $en{$f[2]}, $dt\n"};
	$dtavg += $dt;
	($h,$m,$s) = split(':',$f[4]);
	$tex = $h*3600 + $m*60 + $s;
	$dt = sprintf "%.3f",$tex - $ex{$f[2]}; 
	if ($dt < $dtmin and abs($dt) < 9000) { $dtmin = $dt; print "SAA exit: $f[3] $f[4] $f[2] $en{$f[2]}, new dT min = $dt\n"};
	if ($dt > $dtmax and abs($dt) < 9000) { $dtmax = $dt; print "SAA exit: $f[3] $f[4] $f[2] $en{$f[2]}, new dT max = $dt\n"};
#	$dtmin = $dt if ($dt < $dtmin and abs($dt) < 9000);
#	$dtmax = $dt if ($dt > $dtmax and abs($dt) < 9000);
#	if ($dt > $dtmax) {$dtmax = $dt; print "exit: $f[3] $f[4] $f[2] $ex{$f[2]}, $dt\n"};
	$dtavg += $dt;	
    }
    $dtavg /= $match*2 if ($match);
    $sdtmin = sprintf "%.3f", $dtmin;
    $sdtmax = sprintf "%.3f", $dtmax;
    $sdtavg = sprintf "%.3f", $dtavg;
#    print STDERR "$0: $rep2 differs from $rep1 by up to $sdtmax seconds\n"; 
    print "$rep2, $trans lines, wrt $rep1: min dT = $sdtmin, max dT = $sdtmax, avg dT = $sdtavg, from $match SAAs\n";
}
