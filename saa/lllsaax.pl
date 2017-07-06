#!/usr/local/bin/perl -w

# check a new SAA report against the previous report

# look for and report new SAA reports in the FastCopy archive.
# print out the entry and exit dT's for all matched SAA transits in the pair of reports, to an individual output file
# calculate and report  min, max, avg delta T for the SAA transit times that are common to the 2 reports
# optionally: ignore first and last SAA transits in the checking
# check if either report has duplicated SAA entry orbit numbers
# look for and report SAA transits that appear or disappear in the pair of reports
# finally copy new SAA report from the FastCopy archive into my own archive.

# Robert Cameron
# January 2015

# usage: ./lllsaax.pl
# output goes to STDOUT, STDERR if necessary, and a specific output file in the pairs subdirectory

$verbose = 1;      # put out informational messages
$maxtransit = 999; # the limit to the number of transits to check
$endclip = 1;      # ignore first and last SAA transits in each report, when checking min, max, avg dT.

# path to my working directory 
$wdir = "/u/gl/rac/LATmetrics/saa";
$rdir = "$wdir/reports";
$odir = "$wdir/pairs";

@ylen = (366,365,365,365);

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
print STDERR "$0: latest checked report is $prep\n" if ($verbose);

# path to the FastCopy archive of SAA reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# get recent days' Year/Month/DOY
$day0 = `date +"%Y/%m/%j.*"`;
$day1 = `date --date="yesterday" +"%Y/%m/%j.*"`;
$day2 = `date --date="2 days ago" +"%Y/%m/%j.*"`;
#$day3 = `date --date="3 days ago" +"%Y/%m/%j.*"`;
#$day4 = `date --date="4 days ago" +"%Y/%m/%j.*"`;
#$day5 = `date --date="5 days ago" +"%Y/%m/%j.*"`;
#$day6 = `date --date="6 days ago" +"%Y/%m/%j.*"`;
#$day7 = `date --date="7 days ago" +"%Y/%m/%j.*"`;
chomp $day0;
chomp $day1;
chomp $day2;
#chomp $day3;
#chomp $day4;
#chomp $day5;
#chomp $day6;
#chomp $day7;

# look for recent SAA reports
@d0 = `find $fcdir/$day0 -name 'L20*SAA*'`;
@d1 = `find $fcdir/$day1 -name 'L20*SAA*'`;
@d2 = `find $fcdir/$day2 -name 'L20*SAA*'`;
#@d3 = `find $fcdir/$day3 -name 'L20*SAA*'`;
#@d4 = `find $fcdir/$day4 -name 'L20*SAA*'`;
#@d5 = `find $fcdir/$day5 -name 'L20*SAA*'`;
#@d6 = `find $fcdir/$day6 -name 'L20*SAA*'`;
#@d7 = `find $fcdir/$day7 -name 'L20*SAA*'`;
#exit unless (@d0 or @d1 or @d2 or @d3 or @d4 or @d5 or @d6 or @d7);
#@d = sort (@d7,@d6,@d5,@d4,@d3,@d2,@d1,@d0);
@d = sort (@d2,@d1,@d0);
printf STDERR "$0: %i recent files found\n",scalar(@d) if ($verbose);
exit unless (@d);

#append the names of new SAA reports, in order, into "SAA.reports".
# and copy new SAA reports into the "reports" subdirectory
foreach (@d) {
    chomp;
    print STDERR "$0: processing recent SAA report: $_\n" if ($verbose);
    next if ($xrep{$_});    # report is already listed in 'SAA.reports'
    next unless (/SAA/);
    @f = split('/',$_);
    $rep = $f[-1];
    chomp $rep;
    print STDERR "$0: report pair to be compared: $rep and $prep\n" if ($verbose);
    next if ($rep eq $prep);
    if ($myrep{$rep}) {
	$size0 = `wc $rdir/$rep`;
	chomp $size0;
	@size0 = split('/',$size0);
	$size1 = `wc $_`;
	chomp $size1;
	@size1 = split('/',$size1);
	print STDERR "$0: sizes differ for my $rep and FastCopy version: $size0 and $size1\n" unless ($size0[-1] == $size1[-1]);
    }
    procrep( $_, $prep, $endclip );
    $prep = $rep;
}

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

sub procrep {

# assume the newer report is in the FastCopy archive, and the filename has the path attached
# assume the older report is in my reports subdirectory, and the filename does not include the path

    $fcrep2 = shift;      # the new report, in the FastCopy archive, where the name includes the path
    $rep1 = shift;        # the older report, which is in my reports subdirectory, path not included
    $endclip = shift;     # if set, ignore the first and last transits from each report, getting min/max/avg dT 

    @f = split('/',$fcrep2);
    $rep2 = $f[-1];

### get YYYY and DOY from $rep2 here, to be used for calculating day offsets when dT > 30, 60, 90, 120 seconds

    $rep2 =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $yf2 = $1;
    $df2 = $2;
    $leap = $yf2 % 4;

    $outfilename = "$odir/$rep2-$rep1.match";
    print STDERR "$0: opening matched SAA transit output file $outfilename\n";
    open (OF, ">", $outfilename) or die "$0: Cannot open output file $outfilename\n";

    print STDERR "$0: copying $fcrep2 to my report archive\n" if ($verbose);
    `cp $fcrep2 $rdir`;

    @r1 = `cat $rdir/$rep1`;
    @r2 = `cat $rdir/$rep2`;
    $#r1 = $maxtransit if ($#r1 > $maxtransit);
    $#r2 = $maxtransit if ($#r2 > $maxtransit);
    %en = ();
    %en1 = ();
    @en1 = ();
    %ex = ();
    %en2 = ();
    @en2 = ();
    $y0 = 0;
    %dday1 = ();
    %dday2 = ();
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
	$doy1 = $doy;
	unless ($y0) {
	    $y0 = $y;
	    $extradays = ($y % 4)? 365 : 366;
	}
	$doy += $extradays unless ($y == $y0);
	($h,$m,$s) = split(':',$f[1]);
	$en{$f[2]} = sprintf "%.3f",$doy*86400+$h*3600 + $m*60 + $s;
	$ex{$f[2]} = sprintf "%.3f",$en{$f[2]}+$f[-1]*60;
	$extra = ($y == $yf2)? 0 : $ylen[$leap];
	$dday1{$f[2]} = $doy1 - $df2 + $extra;
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
	print "$0: on day $dday2{$f[2]} of report $rep2, a repeat transit at $f[1] for orbit number $f[2]\n" if ($en2{$f[2]});
	push @en2,$f[2];
	$en2{$f[2]} = "$f[0] $f[1] $f[-1]";
	($d2, $y2) = split('/',$f[0]);
	($doy, $y) = split('/',$f[0]);
	$extra = ($y2 == $yf2)? 0 : $ylen[$leap];
	$dday2{$f[2]} = $d2 - $df2 + $extra;

	next unless ($en{$f[2]});
	$match++;
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
	push @atrans, $trans;
	push @amatch, $match;
	push @aorb, $f[2];
    }
    close(OF) or warn $!;
    
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
    print "checking $rep2 wrt $rep1: $rep2 has $n2 orbits overlapping with $n1 orbits for $rep1\n";
    foreach $o (@en1) { print "\t$rep2 wrt $rep1 is missing a transit at orbit $o at $en1{$o} on report day $dday2{$o}\n" unless ($en2{$o}) };
    foreach $o (@en2) { print "\t$rep2 wrt $rep1 has an extra transit at orbit $o at $en2{$o} on report day $dday2{$o}\n" unless ($en1{$o}) };

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

	for $tt (0..$#dti) { 
	    $dt30 = $tt+$endclip if ($dt30 < 0 and (abs($dti[$tt]) > 30 or (abs($dto[$tt]) > 30)));
	    $dt60 = $tt+$endclip if ($dt60 < 0 and (abs($dti[$tt]) > 60 or (abs($dto[$tt]) > 60)));
	    $dt90 = $tt+$endclip if ($dt90 < 0 and (abs($dti[$tt]) > 90 or (abs($dto[$tt]) > 90)));
	    $dt120 = $tt+$endclip if ($dt120 < 0 and (abs($dti[$tt]) > 120 or (abs($dto[$tt]) > 120)));
	}
	
	@dt = sort { $a <=> $b } (@dti,@dto);
	$dtmin = $dt[0];
	$dtmax = $dt[-1];
	foreach (@dt) { $dtavg += $_ };
	$dtavg /= $match*2;
	$dtavg = sprintf "%.3f",$dtavg;
    } 
    print "$rep2, $trans lines, wrt $rep1: $match matched SAAs: min, max, avg dT = $dtmin, $dtmax, $dtavg\n";
#    print "\t$rep2 wrt $rep1: abs(dT) > 30s at matched SAA transit $dt30\n" if ($dt30 ge 0); 
#    print "\t$rep2 wrt $rep1: abs(dT) > 60s at matched SAA transit $dt60\n" if ($dt60 ge 0); 
#    print "\t$rep2 wrt $rep1: abs(dT) > 90s at matched SAA transit $dt90\n" if ($dt90 ge 0); 
#    print "\t$rep2 wrt $rep1: abs(dT) > 120s at matched SAA transit $dt120\n" if ($dt120 ge 0);
    print "\t$rep2 wrt $rep1: abs(dT) > 30s at orbit $aorb[$dt30] on report day $dday2{$aorb[$dt30]}\n" if ($dt30 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) > 60s at orbit $aorb[$dt60] on report day $dday2{$aorb[$dt60]}\n" if ($dt60 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) > 90s at orbit $aorb[$dt90] on report day $dday2{$aorb[$dt90]}\n" if ($dt90 ge 0); 
    print "\t$rep2 wrt $rep1: abs(dT) > 120s at orbit $aorb[$dt120] on report day $dday2{$aorb[$dt120]}\n" if ($dt120 ge 0); 

#    if ($dt30 ge 0) {
#	print "\t$rep2 wrt $rep1: abs(dT) > 30s at matched SAA transit $dt30\n";
#	$orb30 = $aorb[$dt30];
#	$dd30 = ;
#	print "\t$rep2 wrt $rep1: abs(dT) > 30s at matched SAA transit $dt30\n";
#	print "\t$rep2 wrt $rep1: abs(dT) > 30s at orbit $aorb[$dt30] on report day $ddays{$aorb[$dt30]}\n";
#    }
# add processed report to SAA.reports
    print STDERR "adding new report to 'SAA.reports':\n\t$_\n" if ($verbose);
    `echo "$fcrep2" >> $wdir/SAA.reports`;
}
