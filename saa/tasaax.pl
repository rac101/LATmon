#!/usr/local/bin/perl -w

# check SAA reports against previous the previous report
# optionally: ignore first and last SAA transits in the checking
# NOTE: this script runs through my private archive of reports

# Robert Cameron
# January 2015

# usage: ./tasaax.pl

$maxtransit = 341; # the limit to the number of transits to check

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
    @dti = ();
    @dto = ();
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
	$dtent = sprintf "%.3f",$ten - $en{$f[2]};
	$dtout = sprintf "%.3f",$tex - $ex{$f[2]}; 
#	print "match $match SAA entry at $f[0] $f[1], orbit: $f[2], entry dT = $dtent and exit dT = $dtout\n";	
	push @dti, $dtent;
	push @dto, $dtout;
    }
    $dtmin = 0;
    $dtmax = 0;
    $dtavg = 0;
    $dt30 = -1;
    $dt60 = -1;
    $dt90 = -1;
    $dt120 = -1;
    if ($match) {

# remove first and last transits from the dT calculations
	pop @dti;
	pop @dto;
	shift @dti;
	shift @dto;
	$match -= 2;

# find transit numbers where abs(dT) exceeds 30s, 60s, 90s, 120s.

	for $tt (0..$#dti) { 
	    $dt30 = $tt+1 if ($dt30 < 0 and (abs($dti[$tt]) > 30 or (abs($dto[$tt]) > 30)));
	    $dt60 = $tt+1 if ($dt60 < 0 and (abs($dti[$tt]) > 60 or (abs($dto[$tt]) > 60)));
	    $dt90 = $tt+1 if ($dt90 < 0 and (abs($dti[$tt]) > 90 or (abs($dto[$tt]) > 90)));
	    $dt120 = $tt+1 if ($dt120 < 0 and (abs($dti[$tt]) > 120 or (abs($dto[$tt]) > 120)));
	}

	@dt = sort { $a <=> $b } (@dti,@dto);
	$dtmin = $dt[0];
	$dtmax = $dt[-1];
	foreach (@dt) { $dtavg += $_ };
	$dtavg /= $match*2;
	$dtavg = sprintf "%.3f",$dtavg;
    } 
    print "$rep2, $trans lines, wrt $rep1: $match matched SAAs: min, max, avg dT = $dtmin, $dtmax, $dtavg\n";
    print "\t$rep2 wrt $rep1: abs(dT) exceeds 30 seconds at matched SAA transit $dt30\n" if ($dt30 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) exceeds 60 seconds at matched SAA transit $dt60\n" if ($dt60 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) exceeds 90 seconds at matched SAA transit $dt90\n" if ($dt90 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) exceeds 120 seconds at matched SAA transit $dt120\n" if ($dt120 ge 0); 
}
