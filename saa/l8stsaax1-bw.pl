#!/usr/local/bin/perl -w

# check the latest SAA report against the previous SAA report

# look for SAA reports in the FastCopy archive.
# optionally: ignore first and last SAA transits in the checking
##check if either report has duplicated SAA entry orbit numbers
##look for and report SAA transits that appear or disappear in the pair of reports

# Robert Cameron
# January 2016

# usage: ./l8stsaax1-bw.pl
# output goes to STDOUT, STDERR
# expect to redirect STDOUT to a file, so this script can be run in cron with minimal output emails
# minimize output to STDERR, so this script can be run in cron with minimal output emails

#print color 'bold blue';
#print "This text is bold blue.\n";
#print color 'reset';
#print colored ['bold yellow on_magenta'], 'Bold yellow on magenta.', "\n";
#print colored (" and this is bold cyan", 'bold cyan'), "\n";

$maxtransit = 999; # the limit to the number of SAA transits to check
$endclip = 1;      # ignore first and last SAA transits in each report, when checking min, max, avg dT.

# The Fermi Mission Weeks start on Thursdays, with MW0 = 2008 May 29 (DOY = 150)
$mw0 = 150;
$SAAwindow = 60;
$SAAwindow2 = $SAAwindow * 2;

# path to the FastCopy archive of SAA reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

$now = `date "+At %F %T; DOY %j"`;

# find the 2 most recent SAA reports from different days: get no more than 1 file per day
# getting SAA reports from different dates reduces the chance of comparing 2 versions of a single SAA report 
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
printf "%i recent SAA Reports found\n",scalar(@d);
$fcrep2 = pop @d;
$fcrep1 = pop @d;
print "Reports being compared are:\n";
print "$fcrep2$fcrep1";

chomp $fcrep1;
chomp $fcrep2;
procrep( $fcrep2, $fcrep1, $endclip);

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

sub procrep {

    $fcrep2 = shift;      # the newer report, in the FastCopy archive, where the name includes the path
    $fcrep1 = shift;      # the older report, in the FastCopy archive, where the name includes the path
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
    printf "%i lines read from $rep1\n",scalar(@r1);
    printf "%i lines read from $rep2\n",scalar(@r2);
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
	print "\tWARNING! in report $rep1, a repeat transit at $f[1] for orbit number $f[2]\n" if ($en{$f[2]});
	push @en1,$f[2];
	$en1{$f[2]} = "$f[0] $f[1] $f[-1]";
	($doy, $y) = split('/',$f[0]);
	$d2008 = day2008($y,$doy);
	($h,$m,$s) = split(':',$f[1]);
	$sod = $h*3600 + $m*60 + $s;
	$mwdt = (($d2008 - $mw0)*86400 + $sod + $SAAwindow) % (86400*7);
	print "\tWARNING! in $rep1, SAA entry within $SAAwindow seconds of MW boundary at $f[0] $f[1]\n" if ($mwdt < $SAAwindow2);
	$en{$f[2]} = sprintf "%.3f",$d2008*86400 + $sod;
	$transecs = $f[-1]*60;
	$ex{$f[2]} = sprintf "%.3f",$en{$f[2]} + $transecs;
	$mwdt = (($d2008 - $mw0)*86400 + $sod + $transecs + $SAAwindow) % (86400*7);
	print "\tWARNING! in $rep1, SAA exit within $SAAwindow seconds of MW boundary at $f[3] $f[4]\n" if ($mwdt < $SAAwindow2);
	print "\tWARNING! in $rep1, Very short SAA transit: $f[-1] minutes = $transecs seconds, at $f[0] $f[1] for orbit number $f[2]\n" if ($f[-1] < 0.4);
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
	print "\tWARNING! in report $rep2, on day $dday2{$f[2]}, a repeat transit at $f[1] for orbit number $f[2]\n" if ($en2{$f[2]});
	push @en2,$f[2];
	$en2{$f[2]} = "$f[0] $f[1] $f[-1]";
	($doy, $y) = split('/',$f[0]);
	$d2008 = day2008($y,$doy);
	($h,$m,$s) = split(':',$f[1]);
	$sod = $h*3600 + $m*60 + $s;
	$mwdt = (($d2008 - $mw0)*86400 + $sod + $SAAwindow) % (86400*7);
	print "\tWARNING! in $rep2, SAA entry within $SAAwindow seconds of MW boundary at $f[0] $f[1]\n" if ($mwdt < $SAAwindow2);
	$transecs = $f[-1]*60;
	$mwdt = (($d2008 - $mw0)*86400 + $sod + $transecs + $SAAwindow) % (86400*7);
	print "\tWARNING! in $rep2, SAA exit within $SAAwindow seconds of MW boundary at $f[3] $f[4]\n" if ($mwdt < $SAAwindow2);
	print "\tWARNING! in $rep2, Very short SAA transit: $f[-1] minutes = $transecs seconds, at $f[0] $f[1] for orbit number $f[2]\n" if ($f[-1] < 0.4);

	$dday2{$f[2]} = $d2008 - $rep2008;

	next unless ($en{$f[2]});
	$match++;
	$ten = $d2008*86400 + $sod;
	$tex = $ten + $transecs;
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
    foreach $o (@en1) { print "$rep2 wrt $rep1 is missing a transit at orbit $o at $en1{$o} on report day $dday1{$o}\n" unless ($en2{$o}) }
    foreach $o (@en2) { print "$rep2 wrt $rep1 has an extra transit at orbit $o at $en2{$o} on report day $dday2{$o}\n" unless ($en1{$o}) }

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

    print "$rep2, $trans lines, wrt $rep1: $match matched SAAs: Min, Avg, Max dT (sec) = $dtmin, $dtavg, $dtmax\n";
    print "\t$rep2 wrt $rep1: abs(dT) > 30s at orbit $aorb[$dt30] on report day $dday2{$aorb[$dt30]}\n" if ($dt30 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) > 60s at orbit $aorb[$dt60] on report day $dday2{$aorb[$dt60]}\n" if ($dt60 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) > 90s at orbit $aorb[$dt90] on report day $dday2{$aorb[$dt90]}\n" if ($dt90 ge 0);
    print "\t$rep2 wrt $rep1: abs(dT) > 120s at orbit $aorb[$dt120] on report day $dday2{$aorb[$dt120]}\n" if ($dt120 ge 0); 

    print "\n";
}

sub day2008 {   # convert (y,doy) into number of days since start of 2008
    my $year = shift;
    my $doy = shift;
    my $delyear = $year - 2008;
    my $leapdays = int (($delyear+3)/4);
    $answer = $delyear*365 + $doy + $leapdays;
    return $answer;
}
