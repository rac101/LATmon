#!/usr/local/bin/perl -w

# check the latest SAA report against the previous report

# look for and report new SAA reports in the FastCopy archive.
# optionally: ignore first and last SAA transits in the checking
##check if either report has duplicated SAA entry orbit numbers
##look for and report SAA transits that appear or disappear in the pair of reports
# finally copy new SAA report from the FastCopy archive into my own archive.

# Robert Cameron
# January 2016

# usage: ./l8stsaax1.pl
# output goes to STDOUT, STDERR

use Term::ANSIColor;

#print color 'bold blue';
#print "This text is bold blue.\n";
#print color 'reset';
#print colored ['bold yellow on_magenta'], 'Bold yellow on magenta.', "\n";
#print colored (" and this is bold cyan", 'bold cyan'), "\n";

$maxtransit = 999; # the limit to the number of SAA transits to check
$endclip = 1;      # ignore first and last SAA transits in each report, when checking min, max, avg dT.

# path to the FastCopy archive of SAA reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

$now = `date "+At %F %T; DOY %j"`;

# find the 2 most recent SAA reports, and ensure they are from different dates
$dold = 0;

@rr = ();
until (scalar(@rr) >= 2) { 
    $day = `date --date="$dold days ago" +"%Y/%m/%j.*"`;
    chomp $day;
    @r = `find $fcdir/$day -name 'L20*SAA*'`;
    if (@r) {
	@sr = sort (@r);
	push @rr,$sr[-1];
    }
    $dold++;
}

@d = sort (@rr);
exit unless (@d);

print $now;
printf colored ("%i recent SAA Reports found\n",'green'),scalar(@d);
$fcrep2 = pop @d;
$fcrep1 = pop @d;
print "Reports being compared are:\n";
print colored ("$fcrep2$fcrep1",'green');

chomp $fcrep1;
chomp $fcrep2;
procrep( $fcrep2, $fcrep1, $endclip);

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

sub procrep {

# assume the newer report is in the FastCopy archive, and the filename has the path attached
# assume the older report is in my reports subdirectory, and the filename does not include the path

    $fcrep2 = shift;      # the new report, in the FastCopy archive, where the name includes the path
    $fcrep1 = shift;        # the older report, which is in my reports subdirectory, path not included
    $endclip = shift;     # if set, ignore the first and last transits from each report, getting min/max/avg dT 

    @f = split('/',$fcrep2);
    $rep2 = $f[-1];
    @f = split('/',$fcrep1);
    $rep1 = $f[-1];

# get YYYY and DOY from $rep2 here, to be used for calculating day offsets when dT > 30, 60, 90, 120 seconds

    $rep2 =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $rep2008 = day2008($1,$2);

    @r1 = `cat $fcrep1`;
    @r2 = `cat $fcrep2`;
    printf colored ("%i lines read from $rep1\n",'magenta'),scalar(@r1);
    printf colored ("%i lines read from $rep2\n",'magenta'),scalar(@r2);
    $#r1 = $maxtransit if ($#r1 > $maxtransit);
    $#r2 = $maxtransit if ($#r2 > $maxtransit);
    %en = ();
    %en1 = ();
    @en1 = ();
    %ex = ();
    %en2 = ();
    @en2 = ();
    %dday1 = ();
    %dday2 = ();
    foreach (@r1) {
	next unless (/\/20/);
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	print colored ("in report $rep1, a repeat transit at $f[1] for orbit number $f[2]\n",'red') if ($en{$f[2]});
	push @en1,$f[2];
	$en1{$f[2]} = "$f[0] $f[1] $f[-1]";
	($doy, $y) = split('/',$f[0]);
	$d2008 = day2008($y,$doy);
	($h,$m,$s) = split(':',$f[1]);
	$en{$f[2]} = sprintf "%.3f",$d2008*86400+$h*3600 + $m*60 + $s;
	$ex{$f[2]} = sprintf "%.3f",$en{$f[2]}+$f[-1]*60;
	$dday1{$f[2]} = $d2008 - $rep2008;
    }
    $trans = 0;
    $match = 0;
    @dti = ();
    @dto = ();
    @atrans = ();
    @amatch = ();
    @aorb = ();
    foreach (@r2) {
	next unless (/\/20/);
	$trans++;
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	print colored ("on day $dday2{$f[2]} of report $rep2, a repeat transit at $f[1] for orbit number $f[2]\n",'red') if ($en2{$f[2]});
	push @en2,$f[2];
	$en2{$f[2]} = "$f[0] $f[1] $f[-1]";
	($doy, $y) = split('/',$f[0]);
	$d2008 = day2008($y,$doy);
	$dday2{$f[2]} = $d2008 - $rep2008;

	next unless ($en{$f[2]});
	$match++;
	($h,$m,$s) = split(':',$f[1]);
	$ten = $d2008*86400+$h*3600 + $m*60 + $s;
	$tex = $ten+$f[-1]*60;
	$dtent = sprintf "%.3f",$ten - $en{$f[2]};
	$dtout = sprintf "%.3f",$tex - $ex{$f[2]}; 
#	print colored ("$f[0] $f[1], orbit: $f[2], $match matched SAA: entry and exit dT = $dtent $dtout\n",'blue');
	push @dti, $dtent;
	push @dto, $dtout;
	push @atrans, $trans;
	push @amatch, $match;
	push @aorb, $f[2];
    }
    
# now check for appearing or disappearing orbits

    next unless (@en1 and @en2);
    $first = ($en1[0] > $en2[0])? $en1[0] : $en2[0];
    $last = ($en1[-1] > $en2[-1])? $en2[-1] : $en1[-1];
    while (@en1 and ($en1[0] < $first)) { shift @en1 };
    while (@en2 and ($en2[0] < $first)) { shift @en2 };
    while (@en1 and ($en1[-1] > $last)) { pop @en1 };
    while (@en2 and ($en2[-1] > $last)) { pop @en2 };
    $n1 = scalar(@en1);
    $n2 = scalar(@en2);
    print "checking $rep2 wrt $rep1: $n2 orbits overlapping with $n1 orbits\n";
    foreach $o (@en1) { 
	print colored ("$rep2 wrt $rep1 is missing a transit at orbit $o at $en1{$o} on report day $dday1{$o}\n",'red') unless ($en2{$o});
    }
    foreach $o (@en2) { 
	print colored ("$rep2 wrt $rep1 has an extra transit at orbit $o at $en2{$o} on report day $dday2{$o}\n",'red') unless ($en1{$o});
    }
# find and report the min, max, and avg dT for the SAA transits common to the 2 reports

    $dtmin = 0;
    $dtmax = 0;
    $dtavg = 0;
    $dt30 = -1;
    $dt60 = -1;
    $dt90 = -1;
    $dt120 = -1;
    if ($match) {

# optionally remove first and last transits from the dT calculations

	if ($endclip) {
	    pop @dti;
	    pop @dto;
	    shift @dti;
	    shift @dto;
	    $match -= 2;
	}

# find and report transit numbers where abs(dT) exceeds 30s, 60s, 90s, 120s.

	for $mt (0..$#dti) { 
	    $dt30 = $mt+$endclip if ($dt30 < 0 and (abs($dti[$mt]) > 30 or (abs($dto[$mt]) > 30)));
	    $dt60 = $mt+$endclip if ($dt60 < 0 and (abs($dti[$mt]) > 60 or (abs($dto[$mt]) > 60)));
	    $dt90 = $mt+$endclip if ($dt90 < 0 and (abs($dti[$mt]) > 90 or (abs($dto[$mt]) > 90)));
	    $dt120 = $mt+$endclip if ($dt120 < 0 and (abs($dti[$mt]) > 120 or (abs($dto[$mt]) > 120)));
	}
	
	@dt = sort { $a <=> $b } (@dti,@dto);
	$dtmin = $dt[0];
	$dtmax = $dt[-1];
	foreach (@dt) { $dtavg += $_ };
	$dtavg /= $match*2;
	$dtavg = sprintf "%.3f",$dtavg;
    } 

#    $today = `date '+%F %j'`;
#    print "Today is [date, doy]:  $today";
    print "$rep2, $trans lines, wrt $rep1: $match matched SAAs: min, max, avg dT = $dtmin, $dtmax, $dtavg\n";
    print colored ("\t$rep2 wrt $rep1: abs(dT) > 30s at orbit $aorb[$dt30] on report day $dday2{$aorb[$dt30]}\n",'green') if ($dt30 ge 0); 
    print colored ("\t$rep2 wrt $rep1: abs(dT) > 60s at orbit $aorb[$dt60] on report day $dday2{$aorb[$dt60]}\n",'green') if ($dt60 ge 0); 
    print colored ("\t$rep2 wrt $rep1: abs(dT) > 90s at orbit $aorb[$dt90] on report day $dday2{$aorb[$dt90]}\n",'green') if ($dt90 ge 0); 
    print colored ("\t$rep2 wrt $rep1: abs(dT) > 120s at orbit $aorb[$dt120] on report day $dday2{$aorb[$dt120]}\n",'green') if ($dt120 ge 0); 
}

sub day2008 {   # convert (y,doy) into number of days since start of 2008
    my $year = shift;
    my $doy = shift;
    my $delyear = $year - 2008;
    my $leapdays = int (($delyear+3)/4);
    $answer = $delyear*365 + $doy + $leapdays;
    return $answer;
}
