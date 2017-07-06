#!/usr/local/bin/perl -w

# check a SAA report against the previous report
# print out the entry and exit dT's for all matched SAA transits in the pair of reports, to an individual output file
# calculate and report  min, max, avg delta T for the SAA transit times that are common to the 2 reports
# optionally: ignore first and last SAA transits in the checking
# check if either report has duplicated SAA entry orbit numbers
# from psaax.pl: look for and report new SAA reports in the FastCopy archive.
# look for and report SAA transits that appear or disappear in the pair of reports
# finally from mv2arch.pl: copy new SAA report from the FastCopy archive into my own archive.

# Robert Cameron
# January 2015

# usage: ./lsaax.pl new-report-in-FastCopy old-report-in-reports-subdirectory
# output goes to STDOUT, STDERR if necessary, and a specific output file in the pairs subdirectory

$maxtransit = 999; # the limit to the number of transits to check

# path to my archive of SAA reports 
$idir = "/u/gl/rac/LATmetrics/saa/reports";
$odir = "/u/gl/rac/LATmetrics/saa/pairs";

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

($rep2,$rep1) = @ARGV;

$outfilename = "$odir/$rep2-$rep1.match";
print STDERR "$0: opening matched SAA transit output file $outfilename\n";
open (OF, ">", $outfilename) or die "$0: Cannot open output file $outfilename\n";

@r1 = `cat $idir/$rep1`;
@r2 = `cat $idir/$rep2`;
$#r1 = $maxtransit if ($#r1 > $maxtransit);
$#r2 = $maxtransit if ($#r2 > $maxtransit);
%en = ();
%en1 = ();
@en1 = ();
%ex = ();
%en2 = ();
@en2 = ();
$y0 = 0;
foreach (@r1) {
    next unless (/\/20/);
    chomp;
    s/"/ /g;
    s/,/ /g;
    @f = split;
    print "$0: in report $rep1, a repeat transit at $f[1] for orbit number $f[2]\n" if ($en{$f[2]});
    push @en1,$f[2];
    $en1{$f[2]} = "$f[0] $f[1] $f[-1]";
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
    print "$0: in report $rep2, a repeat transit at $f[1] for orbit number $f[2]\n" if ($en2{$f[2]});
    push @en2,$f[2];
    $en2{$f[2]} = "$f[0] $f[1] $f[-1]";
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
    print OF "$f[0] $f[1], orbit: $f[2], $match matched SAA: entry and exit dT = $dtent $dtout\n";
    push @dti, $dtent;
    push @dto, $dtout;
}
close(OF) or warn $!;

next unless (@en1 and @en2);
$first = ($en1[0] > $en2[0])? $en1[0] : $en2[0];
$last = ($en1[-1] > $en2[-1])? $en2[-1] : $en1[-1];
while (@en1 and ($en1[0] < $first)) { shift @en1 };
while (@en2 and ($en2[0] < $first)) { shift @en2 };
while (@en1 and ($en1[-1] > $last)) { pop @en1 };
while (@en2 and ($en2[-1] > $last)) { pop @en2 };
$n1 = scalar(@en1);
$n2 = scalar(@en2);
print "checking $rep2 wrt $rep1: $rep2 has $n2 orbits overlapping with $n1 orbits for $rep1\n";
foreach $o (@en1) { print "\t$rep2 wrt $rep1 is missing a transit at orbit $o at $en1{$o}\n" unless ($en2{$o}) };
foreach $o (@en2) { print "\t$rep1 wrt $rep2 is missing a transit at orbit $o at $en2{$o}\n" unless ($en1{$o}) };

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
