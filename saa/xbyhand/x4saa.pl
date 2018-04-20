#!/usr/local/bin/perl -w

# check a new SAA report against a previous report

##print out the entry and exit dT's for all matched SAA transits in the pair of reports, to an output file
##calculate and report  min, max, avg delta T for the SAA transit times that are common to the 2 reports
# optionally: ignore first and last SAA transits in the checking
##check if either report has duplicated SAA entry orbit numbers
##look for and report SAA transits that appear or disappear in the pair of reports

# Robert Cameron
# January 2018

# usage: ./2saax.pl new-saa-report-with-path reference-saa-report-with-path
# output goes to STDOUT, STDERR if necessary, and a specific output file in the pairs subdirectory

# assume the report names have the format: LyyyydddSAA.vv

use File::Basename;
$sn = basename($0);

#$verbose = 1;      # put out informational messages
$maxtransit = 999; # the limit to the number of transits to check
$endclip = 1;      # ignore first and last SAA transits in each report, when checking min, max, avg dT.

($rep,$prep) = @ARGV;

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

# The Fermi Mission Weeks start on Thursdays, with MW0 = 2008 May 29 (DOY = 150)
$mwzero = 150;

# some time tolerances, in seconds
$SAAwindow = 60;
#$SAAwindow2 = $SAAwindow * 2;
$shortSAA = 30;

# path to my working directory 
$wdir = "/u/gl/rac/LATmetrics/saa";
$rdir = "$wdir/reports";
$odir = "$wdir/pairs";

procrep( $rep, $prep, $endclip );

# add processed report to "SAA.reports" file

#print STDERR "$sn: adding new report to 'SAA.reports':\n  $rep\n" if ($verbose);
#`echo "$rep" >> $wdir/SAA.reports`;

sub procrep {

# assume the newer report is in the FastCopy archive, and the filename has the path attached
# assume the older report is in my reports subdirectory, and the filename does not include the path

    $fcrep2 = shift;      # the new ("2") report, in the FastCopy archive, where the name includes the path
    $rep1 = shift;        # the older ("1") report, which is in my reports subdirectory, path not included
    $endclip = shift;     # if set, ignore the first and last transits from each report in getting min,avg,max dT 

    $fcrrep2 = $fcrep2;   # make a multi-line version of the path+SAA report file name, for printing
    $fcrrep2 =~ s/fcopy\//fcopy\/\n  /;
    $fcrrep2 =~ s/\/L20/\n  \/L20/;

    @f = split('/',$fcrep2);
    $rep2 = $f[-1];

    $outfilename = "$odir/$rep2-$rep1.match";
    $outfilename2 = "$odir/\n  $rep2-$rep1.match";
    print STDERR "$sn: Opening matched SAA transit output file:\n $outfilename2\n";
    open (OF, ">", $outfilename) or die "$0: Cannot open output file $outfilename\n";

#    print STDERR "$sn: copying\n $fcrrep2\n to my SAA report archive in\n $rdir\n" if ($verbose);
#    `cp $fcrep2 $rdir`;

    @r1 = `cat $rdir/$rep1`;   # the old report
    @r2 = `cat $rdir/$rep2`;   # the new report
    $date = `date +"%F"`;
    chomp $date;
    p2("$date: $sn: checking $#r2 lines in $rep2 wrt $#r1 lines in $rep1\n");
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
#	p2("WARNING! In $rep1, SAA entry within $SAAwindow seconds of MW boundary at $dyt0 on report day $rday0\n") if ($mw0 < $SAAwindow);
#	p2("WARNING! In $rep1, SAA exit within $SAAwindow seconds of MW boundary at $dyt1 on report day $rday1\n") if ($mw1 < $SAAwindow);
#	p2("WARNING! In $rep1, Very short SAA transit: $durm minutes = $durs seconds, at $dyt0 on report day $rday0 = orbit $orb0\n") if ($durs < $shortSAA);
#	p2("ERROR! In $rep1, a repeat SAA transit at $dyt0 on report day $rday0 = orbit $orb0\n") if ($en1{$orb0});
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
	p2("WARNING! In $rep2, SAA entry within $SAAwindow seconds of MW boundary at $dyt0 on report day $rday0\n") if ($mw0 < $SAAwindow);
	p2("WARNING! In $rep2, SAA exit within $SAAwindow seconds of MW boundary at $dyt1 on report day $rday1\n") if ($mw1 < $SAAwindow);
	p2("WARNING! In $rep2, Very short SAA transit: $durm minutes = $durs seconds, at $dyt0 on report day $rday0 = orbit $orb0\n") if ($durs < $shortSAA);
	p2("ERROR! In $rep2, a repeat SAA transit at $dyt0 on report day $rday0 = orbit $orb0\n") if ($en2{$orb0});
	push @en2,$orb0;
	$en2{$orb0} = "$dyt0 for $durm minutes";
	$dday2{$orb0} = $rday0;

	next unless ($en{$orb0});
	$match++;
	$dtent = $t0 - $en{$orb0};
	$dtout = $t1 - $ex{$orb0}; 
	print OF "$dyt0, orbit: $orb0, $match matched SAA: entry and exit dT = $dtent $dtout\n";
	push @dti, $dtent;
	push @dto, $dtout;
	push @atrans, $trans;
	push @amatch, $match;
	push @aorb, $orb0;
    }
    close(OF) or warn $!;
    
# check for and report any appearing or disappearing orbits

    next unless (@en1 and @en2);
    $first = ($en1[0] > $en2[0])? $en1[0] : $en2[0];
    $last = ($en1[-1] > $en2[-1])? $en2[-1] : $en1[-1];
    while (@en1 and ($en1[0] < $first)) { shift @en1 };
    while (@en2 and ($en2[0] < $first)) { shift @en2 };
    while (@en1 and ($en1[-1] > $last)) { pop @en1 };
    while (@en2 and ($en2[-1] > $last)) { pop @en2 };
    $n1 = scalar(@en1);
    $n2 = scalar(@en2);
    p2(" $n2 orbits in $rep2 overlapping with $n1 orbits in $rep1\n");
    foreach $o (@en1) {p2("\t$rep2 wrt $rep1 is missing a transit at orbit $o at $en1{$o} on report day $dday1{$o}\n") unless ($en2{$o})};
    foreach $o (@en2) {p2("\t$rep2 wrt $rep1 has an extra transit at orbit $o at $en2{$o} on report day $dday2{$o}\n") unless ($en1{$o})};

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
    p2(" $rep2 wrt $rep1: $match matched SAAs: Min, Avg, Max dT (sec) = $dtmin, $dtavg, $dtmax\n");
    p2("\tNOTE: $rep2 wrt $rep1: abs(dT) > 30s at orbit $aorb[$dt30] on report day $dday2{$aorb[$dt30]}\n") if ($dt30 ge 0); 
    p2("\tNOTE: $rep2 wrt $rep1: abs(dT) > 60s at orbit $aorb[$dt60] on report day $dday2{$aorb[$dt60]}\n") if ($dt60 ge 0); 
    p2("\tNOTE: $rep2 wrt $rep1: abs(dT) > 90s at orbit $aorb[$dt90] on report day $dday2{$aorb[$dt90]}\n") if ($dt90 ge 0); 
    p2("\tNOTE: $rep2 wrt $rep1: abs(dT) > 120s at orbit $aorb[$dt120] on report day $dday2{$aorb[$dt120]}\n") if ($dt120 ge 0); 
    p2("\n");
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

sub p2 {     # print a message to both STDOUT and STDERR
    my $msg = shift;
    print $msg;
    print STDERR $msg;
}
