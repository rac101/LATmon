#!/usr/local/bin/perl -w

# check the latest SAA report against the previous report

# look for and report new SAA reports in the FastCopy archive.
##print out the entry and exit dT's for all matched SAA transits in the pair of reports, to an individual output file
##calculate and report  min, max, avg delta T for the matched SAA transits in the pair of reports
# optionally: ignore first and last SAA transits in the checking
##check if either report has duplicated SAA entry orbit numbers
##look for and report SAA transits that appear or disappear in the pair of reports
# finally copy new SAA report from the FastCopy archive into my own archive.

# Robert Cameron
# April 2015

# usage: ./l8stsaax.pl
# output goes to STDOUT, STDERR

use File::Basename;
$sn = basename($0);

use Term::ANSIColor;
use Getopt::Long;

$colour = 0;
GetOptions ("colour"  => \$colour)  # flag: 1 = colour printout
    or die("$sn: Error in command line arguments\n");

$maxtransit = 999; # the limit to the number of SAA transits to check
$endclip = 1;      # ignore first and last SAA transits in each report, when checking min, max, avg dT.
$shortSAA = 30;
$SAAwindow = 30;
$mwzero = 150;

# path to the FastCopy archive of SAA reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# find the 2 most recent SAA reports
$dold = 0;
@rr = ();
until (scalar(@rr) >= 2) { 
    $day = `date --date="$dold days ago" +"%Y/%m/%j.*"`;
    chomp $day;
    @r = `find $fcdir/$day -name 'L20*SAA*'`;
    push @rr,@r if (@r);
    $dold++;
}

@d = sort (@rr);
exit unless (@d);
$nd = scalar(@d);
$date = `date +"$sn: at %F %T; DOY %j"`;

print "$date $nd recent reports found\n";
$fcrep2 = pop @d;
$fcrep1 = pop @d;
pc("$sn: Reports being compared are:\n $fcrep2 $fcrep1",'green');

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
    pc(" checking $#r2 lines in $rep2 wrt $#r1 lines in $rep1\n",'magenta');
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
        ($dyt0,$orb0,$rday0,$mw0,$t0,$dyt1,$orb1,$rday1,$mw1,$t1,$durm,$durs) = readrec($_,$rep1);
	push @en1,$orb0;
	$en1{$orb0} = "$dyt0 for $durm minutes";
#pc("WARNING! In $rep1, SAA entry within $SAAwindow seconds of MW boundary at $dyt0 on report day $rday0\n",'red') if ($mw0 < $SAAwindow);
#pc("WARNING! In $rep1, SAA exit within $SAAwindow seconds of MW boundary at $dyt1 on report day $rday1\n",'red') if ($mw1 < $SAAwindow);
#pc("WARNING! In $rep1, Very short SAA transit: $durm minutes = $durs seconds, at $dyt0 on report day $rday0 = orbit $orb0\n",'red') if ($durs < $shortSAA);
#pc("ERROR! In $rep1, a repeat SAA transit at $dyt0 on report day $rday0 = orbit $orb0\n",'red') if ($en1{$orb0});
	$en{$orb0} = $t0;
	$ex{$orb0} = $t1;
	$dday1{$orb0} = $rday0;
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
        ($dyt0,$orb0,$rday0,$mw0,$t0,$dyt1,$orb1,$rday1,$mw1,$t1,$durm,$durs) = readrec($_,$rep2);
	pc("WARNING! In $rep2, SAA entry within $SAAwindow seconds of MW boundary at $dyt0 on report day $rday0\n",'red') if ($mw0 < $SAAwindow);
	pc("WARNING! In $rep2, SAA exit within $SAAwindow seconds of MW boundary at $dyt1 on report day $rday1\n",'red') if ($mw1 < $SAAwindow);
	pc("WARNING! In $rep2, Very short SAA transit: $durm minutes = $durs seconds, at $dyt0 on report day $rday0 = orbit $orb0\n",'red') if ($durs < $shortSAA);
	pc("ERROR! In $rep2, a repeat SAA transit at $dyt0 on report day $rday0 = orbit $orb0\n",'red') if ($en2{$orb0});
	push @en2,$orb0;
	$en2{$orb0} = "$dyt0 for $durm minutes";
	$dday2{$orb0} = $rday0;

	next unless ($en{$orb0});
	$match++;
	$dtent = $t0 - $en{$orb0};
	$dtout = $t1 - $ex{$orb0}; 
#	pc("$dyt0, orbit: $orb0, $match matched SAA: entry and exit dT = $dtent $dtout\n",'blue');
	push @dti, $dtent;
	push @dto, $dtout;
	push @atrans, $trans;
	push @amatch, $match;
	push @aorb, $orb0;
    }

# now check for appearing or disappearing orbits

    next unless (@en1 and @en2);
    $first = ($en1[0] > $en2[0])? $en1[0] : $en2[0];
    $last = ($en1[-1] > $en2[-1])? $en2[-1] : $en1[-1];
    while (@en1 and ($en1[0] < $first)) { shift @en1 };
    while (@en2 and ($en2[0] < $first)) { shift @en2 };
    while (@en1 and ($en1[-1] > $last)) { pop @en1 };
    while (@en2 and ($en2[-1] > $last)) { pop @en2 };
#    $n1 = scalar(@en1);
#    $n2 = scalar(@en2);
    foreach $o (@en1) { 
	pc("$rep2 wrt $rep1 is missing a transit at orbit $o at $en1{$o} on report day $dday1{$o}\n",'red') unless ($en2{$o});
    }
    foreach $o (@en2) { 
	pc("$rep2 wrt $rep1 has an extra transit at orbit $o at $en2{$o} on report day $dday2{$o}\n",'red') unless ($en1{$o});
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
	$dtmin = sprintf "%.3f",$dt[0];
	$dtmax = sprintf "%.3f",$dt[-1];
	foreach (@dt) { $dtavg += $_ };
	$dtavg /= scalar(@dt);
	$dtavg = sprintf "%.3f",$dtavg;
    } 

    pc("$rep2 wrt $rep1: $match matched SAAs: min, avg, max dT (sec) = $dtmin, $dtavg, $dtmax\n",'blue');
    pc("\t$rep2 wrt $rep1: abs(dT) > 30s at orbit $aorb[$dt30] on report day $dday2{$aorb[$dt30]}\n",'green') if ($dt30 ge 0); 
    pc("\t$rep2 wrt $rep1: abs(dT) > 60s at orbit $aorb[$dt60] on report day $dday2{$aorb[$dt60]}\n",'green') if ($dt60 ge 0); 
    pc("\t$rep2 wrt $rep1: abs(dT) > 90s at orbit $aorb[$dt90] on report day $dday2{$aorb[$dt90]}\n",'green') if ($dt90 ge 0); 
    pc("\t$rep2 wrt $rep1: abs(dT) > 120s at orbit $aorb[$dt120] on report day $dday2{$aorb[$dt120]}\n",'green') if ($dt120 ge 0); 
}

sub readrec {   # decode a SAA transit record into useful values, using the SAA report name
    my $rec = shift;
    my $rep = shift;

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

# returns = ($dyt0,$orb0,$rday0,$mw0,$t0,$dyt1,$orb1,$rday1,$mw1,$t1,$durm,$durs)
# where suffix 0 -> SAA entry, suffix 1 -> SAA exit
# $dyt = doy/yyyy hh:mm:ss
# $orb = orbit number
# $sod = seconds of day
# $rday = report day
# $mw = absolute seconds from Mission Week boundary
# $t = formatted (using sprintf "%.3f") seconds since the start of 2008
# $durm = SAA transit duration in minutes
# $durs = SAA transit duration in seconds

# decode the SAA transit record line

    chomp $rec;
    $rec =~ s/"/ /g;
    $rec =~ s/,/ /g;
    ($date0,$time0,$orb0,$date1,$time1,$orb1,$durm) = split(' ',$rec);
    $durs = $durm * 60.0;
  
    ($dyt0,$rday0,$mw0,$t0) = DateTimeParse($date0,$time0,$rep);
    ($dyt1,$rday1,$mw1,$t1) = DateTimeParse($date1,$time1,$rep);

    return $dyt0,$orb0,$rday0,$mw0,$t0,$dyt1,$orb1,$rday1,$mw1,$t1,$durm,$durs;
}

sub DateTimeParse {   # decode a SAA transit record into useful values, using the SAA report name
    my $date = shift;
    my $time = shift;
    my $rep = shift;

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

# returns = ($dyt,$rday,$mw,$t)
# $dyt = doy/yyyy hh:mm:ss
# $sod = seconds of day
# $rday = report day
# $mw = absolute seconds from Mission Week boundary
# $t = formatted (using sprintf "%.3f") seconds since the start of 2008

# get YYYY and DOY from report name, to be used for calculating report day offsets

    $rep =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $rep2008 = day2008($1,$2);

    $week = 86400.0 * 7;
    $halfweek = $week/2.0;

# decode the Date and Time

    ($doy, $y) = split('/',$date);
    $d2008 = day2008($y,$doy);
    $rday = $d2008 - $rep2008;
    $dyt = "$date $time";
    ($h,$m,$s) = split(':',$time);
    $sod = $h*3600 + $m*60 + $s;
    $mw = (($d2008 - $mwzero) % 7) * 86400.0 + $sod;
    $mw = $week - $mw if ($mw > $halfweek);
    $t = $d2008 * 86400.0 + $sod;

    return $dyt,$rday,$mw,$t;

}

sub day2008 {   # convert (y,doy) into number of days since start of 2008
    my $year = shift;
    my $doy = shift;
    my $delyear = $year - 2008;
    my $leapdays = int (($delyear+3)/4);
    $answer = $delyear*365 + $doy + $leapdays;
    return $answer;
}

sub pc {     # print a message with or without color
    my $msg = shift;
    if ($colour) {
	my $color = shift;
	print colored ($msg,$color);
    } else { 
	print $msg;
    }
}
