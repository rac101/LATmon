#!/usr/local/bin/perl -w

# check SAA reports against previous the previous report
# NOTE: this script runs through my private archive of reports

# Robert Cameron
# January 2015

# usage: ./masaax.pl

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
for $i (405..405) {
    $rep1 = $srep[$i-1];
    $rep2 = $srep[$i];
    chomp $rep1;
    chomp $rep2;
#    print "$0: begin comparing times of SAA transits in $rep2 relative to equivalent times in $rep1\n"; 
    @r1 = `cat $wdir/$rep1`;
    @r2 = `cat $wdir/$rep2`;
#    $#r1 = 341 if ($#r1 > 341);
#    $#r2 = 341 if ($#r2 > 341);
    %en = ();
    %ex = ();
    $y0 = 0;
    foreach (@r1) {
	next unless (/\/20/);
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	print STDERR "$0: in report $rep1, a repeat transit at $f[1] for orbit number $f[2]\n" if ($en{$f[2]});
	($doy, $y) = split('/',$f[0]);
	unless ($y0) {
	    $y0 = $y;
	    $extradays = ($y % 4)? 365 : 366;
	}
	$doy += $extradays unless ($y == $y0);
	($h,$m,$s) = split(':',$f[1]);
	$en{$f[2]} = sprintf "%.3f",$doy*86400+$h*3600 + $m*60 + $s;
	$ex{$f[2]} = sprintf "%.3f",$en{$f[2]}+$f[-1]*60;
    }
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
	($doy, $y) = split('/',$f[0]);
	unless ($y0) {
	    $y0 = $y;
	    $extradays = ($y % 4)? 365 : 366;
	}
	$doy += $extradays unless ($y == $y0);
	($h,$m,$s) = split(':',$f[1]);
	$ten = $doy*86400+$h*3600 + $m*60 + $s;
	$tex = $ten+$f[-1]*60;
	$dti = sprintf "%.3f",$ten - $en{$f[2]}; 
	$dto = sprintf "%.3f",$tex - $ex{$f[2]}; 
	if ($dti < $dtmin and abs($dti) < 9000) { 
	    $dtmin = $dti; 
	    print "SAA entry at $f[0] $f[1], orbit: $f[2], new dT min = $dti\n";
	}
	if ($dti > $dtmax and abs($dti) < 9000) { 
	    $dtmax = $dti; 
	    print "SAA entry at $f[0] $f[1], orbit: $f[2], new dT max = $dti\n";
	}
	$dtavg += $dti;
	if ($dto < $dtmin and abs($dto) < 9000) { 
	    $dtmin = $dto; 
	    print "SAA exit at $f[3] $f[4], orbit: $f[5], new dT min = $dto\n";
	}
	if ($dto > $dtmax and abs($dto) < 9000) { 
	    $dtmax = $dto; 
	    print "SAA exit at $f[3] $f[4], orbit: $f[5], new dT max = $dto\n";
	}
	$dtavg += $dto;	
#	print "orbit $f[2]: entry dT = $dti; exit dT = $dto\n";
    }
    $dtavg /= $match*2 if ($match);
    $sdtmin = sprintf "%.3f", $dtmin;
    $sdtmax = sprintf "%.3f", $dtmax;
    $sdtavg = sprintf "%.3f", $dtavg;
    print "$rep2, $trans lines, wrt $rep1: $match matched SAAs: min, max, avg dT = $sdtmin, $sdtmax, $sdtavg\n";
}
