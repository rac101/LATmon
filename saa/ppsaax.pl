#!/usr/local/bin/perl -w

# check SAA reports against previous the previous report
# print out the entry and exit dT's for all matched SAAs in the pair of reports
# NOTE: this script runs through my private archive of reports

# Robert Cameron
# January 2015

# usage: ./ppsaax.pl

$maxtransit = 999; # the limit to the number of transits to check

# path to my archive of SAA reports 
$idir = "/u/gl/rac/LATmetrics/saa/reports";
$odir = "/u/gl/rac/LATmetrics/saa/pairs";

# read the archived report names into a sorted array
@rep = `cd $idir; ls -1 L20*SAA*`;
@srep = sort (@rep);

# compare successive reports
# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

for $i (1..$#srep) {
    $rep1 = $srep[$i-1];
    $rep2 = $srep[$i];
    chomp $rep1;
    chomp $rep2;
    $outfilename = "$odir/$rep2-$rep1.match";
    print STDERR "$0: opening output file $outfilename\n";
    open (OF, ">", $outfilename) or die "$0: Cannot open output file $outfilename\n";
    @r1 = `cat $idir/$rep1`;
    @r2 = `cat $idir/$rep2`;
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
#    $trans = 0;
    $match = 0;
#    @dti = ();
#    @dto = ();
    foreach (@r2) {
	next unless (/\/20/);
#	$trans++;
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
	print OF "$f[0] $f[1], orbit: $f[2], $match matched SAA: entry and exit dT = $dtent $dtout\n";	
    }
#    close(OF) or warn $!;
    close(OF);
}
