#!/usr/local/bin/perl -w

# check a new SAA report against the previous report

# look for and report new SAA reports in the FastCopy archive.
##print out the entry and exit dT's for all matched SAA transits in the pair of reports, to an individual output file
##calculate and report  min, max, avg delta T for the matched SAA transits in the pair of reports
# optionally: ignore first and last SAA transits in the checking
##check if either report has duplicated SAA entry orbit numbers
##look for and report SAA transits that appear or disappear in the pair of reports
# finally copy new SAA report from the FastCopy archive into my own archive.

# Robert Cameron
# January 2015

# usage: ./x4saa.pl
# output goes to STDOUT, STDERR if necessary, and a specific output file in the pairs subdirectory
# can be silent: no output from this script if there is nothing to update, for running in cron with minimal emails

use File::Basename;
$sn = basename($0);

$verbose = 1;      # 1 = put out informational messages; 2 = output to STDERR even if trying to be silent
$maxtransit = 999; # the limit to the number of SAA transits to check
$endclip = 1;      # ignore first and last SAA transits in each report, when checking min, max, avg dT.

# The Fermi Mission Weeks start on Thursdays, with MW0 = 2008 May 29 (DOY = 150)
$mw0 = 150;
$SAAwindow = 60;
$SAAwindow2 = $SAAwindow * 2;

# path to my working directory 
$wdir = "/u/gl/rac/LATmetrics/saa";
$rdir = "$wdir/reports";
$odir = "$wdir/pairs";

# read the archived report names into a hash
@myrep = `cd $rdir; ls -1 L20*SAA*`;
foreach (@myrep) { chomp; $myrep{$_} = 1 };

# read in the existing list of SAA reports, from the file "SAA.reports"
@xr = `cat $wdir/SAA.reports`;
foreach (@xr) { chomp; $xrep{$_} = 1 };
$prev = '';
until ($prev =~ /L20.*SAA/) { $prev = pop @xr };
@f = split ('/',$prev);
$prep = $f[-1];
chomp $prep;

# path to the FastCopy archive of SAA reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# for several recent days' Year/Month/DOY look for recent SAA reports
# check multiple days in case there was some multi-day report ingest problem

foreach $dold (0..2) { 
    $day = `date --date="$dold days ago" +"%Y/%m/%j.*"`;
    chomp $day;
    @r = `find $fcdir/$day -name 'L20*SAA*'`;
    if (@r) {
#	printf STDERR "$sn: %i SAA files found $dold days ago on day $day\n",scalar(@r) if ($verbose);
	push @d, @r;
    }
}
exit unless (@d);    # this exit is how this script can have no output and run silently
@r = @d;
@d = sort (@r);      # process oldest files first

# append the names of new SAA reports, in order, into "SAA.reports".
# and copy new SAA reports into the "reports" subdirectory
foreach (@d) {
    chomp;
    next if ($xrep{$_});    # skip silently if the report is already listed in 'SAA.reports'
    printf STDERR "$sn: NOTE: %i recent SAA report files found\n",scalar(@d) if ($#d >= 1);
    $rrep = $_;
    $rrep =~ s/fcopy\//fcopy\/\n  /;
    $rrep =~ s/\/L20/\/\n  L20/;
    print STDERR "$sn: processing recent SAA report:\n $rrep\n" if ($verbose);
    print STDERR "$sn: previously checked report is\n  $prep\n" if ($verbose);
    next unless (/SAA/);
    @f = split('/',$_);
    $rep = $f[-1];
    print STDERR "$sn: report pair to be compared:\n $rep and $prep\n" if ($verbose);
    next if ($rep eq $prep);
    if ($myrep{$rep}) {
	$size0 = `wc $rdir/$rep`;
	chomp $size0;
	@size0 = split(' ',$size0);
	$size1 = `wc $_`;
	chomp $size1;
	@size1 = split(' ',$size1);
	print STDERR "$sn: PROBLEM! Sizes differ for my $rep and FastCopy version:\n $size0 and $size1\n" unless ($size0[2] eq $size1[2]);
    }
    procrep( $_, $prep, $endclip );
    $prep = $rep;
}

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

# Process the SAA report

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

# get YYYY and DOY from $rep2 here, to be used for calculating day offsets when dT > 30, 60, 90, 120 seconds

    $rep2 =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $rep2008 = day2008($1,$2);

    $outfilename = "$odir/$rep2-$rep1.match";
    $outfilename2 = "$odir/\n  $rep2-$rep1.match";
    print STDERR "$sn: opening matched SAA transit output file\n $outfilename2\n";
    open (OF, ">", $outfilename) or die "$0: Cannot open output file $outfilename\n";

    print STDERR "$sn: copying\n $fcrrep2\n to my SAA report archive in\n $rdir\n" if ($verbose);
    `cp $fcrep2 $rdir`;

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
	chomp;
	s/"/ /g;
	s/,/ /g;
	@f = split;
	p2("$sn: ERROR! In report $rep1, a repeat SAA transit at $f[1] for orbit number $f[2]\n") if ($en{$f[2]});
	push @en1,$f[2];
	$en1{$f[2]} = "$f[0] $f[1] $f[-1]";
	($doy, $y) = split('/',$f[0]);
	$d2008 = day2008($y,$doy);
	($h,$m,$s) = split(':',$f[1]);
	$sod = $h*3600 + $m*60 + $s + 60;
	$mwdt = (($d2008 - $mw0)*86400 + $sod + $SAAwindow) % (86400*7);
	p2("$sn: WARNING! in $rep1, SAA entry within $SAAwindow seconds of MW boundary for $f[0] $f[1]\n") if ($mwdt < $SAAwindow2);
	$transecs = $f[-1]*60;
	$mwdt = (($d2008 - $mw0)*86400 + $sod + $transecs + $SAAwindow) % (86400*7);
	p2("\tWARNING! in $rep1, SAA exit within $SAAwindow seconds of MW boundary at $f[3] $f[4]\n") if ($mwdt < $SAAwindow2);
	p2("\tWARNING! in $rep1, Very short SAA transit: $f[-1] minutes = $transecs seconds, at $f[0] $f[1] for orbit number $f[2]\n") if ($f[-1] < 0.4);
	$en{$f[2]} = sprintf "%.3f",$d2008*86400 + $sod;
	$ex{$f[2]} = sprintf "%.3f",$en{$f[2]}+$transecs;
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
	p2("\tVery short SAA transit: $f[-1] minutes, in $rep2 at $f[0] $f[1] for orbit number $f[2]\n") if ($f[-1] < 0.4);	
	p2("$sn: ERROR! In $rep2, a repeat SAA transit at $dday2{$f[2]} $f[1] = orbit $f[2]\n") if ($en2{$f[2]});
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
	print OF "$f[0] $f[1], orbit: $f[2], $match matched SAA: entry and exit dT = $dtent $dtout\n";
	push @dti, $dtent;
	push @dto, $dtout;
	push @atrans, $trans;
	push @amatch, $match;
	push @aorb, $f[2];
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
	$dtmin = $dt[0];
	$dtmax = $dt[-1];
	foreach (@dt) { $dtavg += $_ };
	$dtavg /= $match*2;
	$dtavg = sprintf "%.3f",$dtavg;
    } 
    p2("$rep2 wrt $rep1: $match matched SAAs: Min, Avg, Max dT (sec) = $dtmin, $dtavg, $dtmax\n");
    p2("\t$rep2 wrt $rep1: abs(dT) > 30s at orbit $aorb[$dt30] on report day $dday2{$aorb[$dt30]}\n") if ($dt30 ge 0); 
    p2("\t$rep2 wrt $rep1: abs(dT) > 60s at orbit $aorb[$dt60] on report day $dday2{$aorb[$dt60]}\n") if ($dt60 ge 0); 
    p2("\t$rep2 wrt $rep1: abs(dT) > 90s at orbit $aorb[$dt90] on report day $dday2{$aorb[$dt90]}\n") if ($dt90 ge 0); 
    p2("\t$rep2 wrt $rep1: abs(dT) > 120s at orbit $aorb[$dt120] on report day $dday2{$aorb[$dt120]}\n") if ($dt120 ge 0); 

# add processed report to SAA.reports
    print STDERR "$sn: adding new report to 'SAA.reports':\n  $fcrrep2\n" if ($verbose);
    `echo "$fcrep2" >> $wdir/SAA.reports`;
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

sub p2 {     # print a message to both STDOUT and STDERR
    my $msg = shift;
    print $msg;
    print STDERR $msg;
}
