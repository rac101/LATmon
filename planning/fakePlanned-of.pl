#!/usr/local/bin/perl -w

# make a routine weekly LAT "Planned" product, as shown in MP webview
# this script is designed to be run on Mondays, in the late morning
# assume the MOC has FastCopied needed products to the ISOC already
# needed planning products are:
#       1. GLAST ephemeris file
#       2. SAA report file
# output file: $mpmw.planfake

# Robert Cameron
# 2016 January
# 2016 February: omit the first run from the output plan if it spans the start of the MW, to match the MPtool review product 

use File::Basename;
$sn = basename($0);

#output format: NOTE: output lines are ordered by Start Time
#Start Time,End Time,Type,Priority,State,Status,Description
#2016-01-21 00:21:51,2016-01-21 01:36:16,Acquisition,NORMAL,InReview,Unknown,[399] Normal acquisition (default configuration)
#2016-01-22 00:00:00,2016-01-22 00:00:00,ATSList,NORMAL,InReview,Unknown,[399] Dump LRA Statistics Block to SSR  (MPLAN-21)
#2016-01-22 00:10:09,2016-01-22 01:23:49,Acquisition,NORMAL,InReview,Unknown,[399] Normal acquisition (default configuration)
#2016-01-22 01:00:00,2016-01-22 01:02:00,ATSList,NORMAL,InReview,Unknown,[399] Dump SUROM to SSR  (MPLAN-22)
#2016-01-22 01:51:12,2016-01-22 03:01:36,Acquisition,NORMAL,InReview,Unknown,[399] Normal acquisition (default configuration)

# make hash table of cumulative day count keyed by year; 2008 = 0
# and arrays of years and cumulative day count
$daycount = 0;
for $year (2008..2030) {
    push @year,$year;
    push @daycount,$daycount;
    $daycount{$year} = $daycount;
    $daycount += 365;
    $daycount++ unless ($year % 4);
}

# find the mission week
$now = `date -u +"%Y %A %j %w"`;   # year, weekday, DOY, numeric weekday; Thursday = 4.
($ty,$weekday,$tdoy,$today) = split(" ",$now);
$ldnow = $daycount{$ty} + $tdoy;
$ddays = 11 - $today;
$ddays += 7 if ($today > 4);
$plandate = `date -u --date="+$ddays days" +"%F %Y DOY %j"`;
($y,$py,$y,$pdoy) = split (" ",$plandate);
$ldp = $daycount{$py} + $pdoy;
$ld0 = $daycount{2008} + 150; # mission week 0 = 2008-5-29, 2008 DOY 150
$mpmw = ($ldp - $ld0)/7;

$mproot = "/u/gl/rac/LATmetrics/planning";

# find the latest GLAST ephemeris filename and path, at the end of the file $mproot/EPHEM.files
$ephemfile = `tail -1 $mproot/EPHEM.files`;
chomp $ephemfile;

# find the latest SAA report filename and path, at the end of the file $mproot/../saa/SAA.reports
$saafile = `tail -1 $mproot/../saa/SAA.reports`;
chomp $saafile;
       
# next check the dates of when the files were received at the ISOC and the dates in the file names
# to verify that the files are not too old. Typical filenames and paths are of the form:
#/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy/2016/01/004.01.04.Mon/utc14/14.42.21/MOC_2016004094203/GLAST_EPH_2016004_2016064_00.txt
#/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy/2016/01/004.01.04.Mon/utc14/14.44.44/MOC_2016004094431/L2016004SAA.00

@f = split("/",$ephemfile);
@g = split('\.',$f[11]);
$ead = $daycount{$f[9]} + $g[0];
$ephemfilename = $f[-1];
@g = split("_",$ephemfilename);
$ebd = $daycount{int($g[2]/1000)} + ($g[2] % 1000);

@f = split("/",$saafile);
@g = split('\.',$f[11]);
$sad = $daycount{$f[9]} + $g[0];
$saafilename = $f[-1];
$f[-1] =~ /L(\d+)SAA.*/;
$sbd = $daycount{int($1/1000)} + ($1 % 1000);

# silent exit from the script if the planning date is not compatible with an input file date
exit if (abs($ldp-$ead-10) > 2);
exit if (abs($ldp-$ebd-10) > 2);
exit if (abs($ldp-$sad-10) > 2);
exit if (abs($ldp-$sbd-10) > 2);

$outfile = "$mproot/$mpmw.planfake";
exit if (-e $outfile);

($junk,$ephemfiletrunc) = split ("fcopy",$ephemfile);
($junk,$saafiletrunc) = split ("fcopy",$saafile);
$ephemfiletrunc =~ s/GLAST_EPH_20/\n   GLAST_EPH_20/;
$saafiletrunc =~ s/L20/\n   L20/;
print STDERR "$sn: today = $weekday = $ldnow; ATS planning day $ldp\n";
print STDERR "$sn: plan mission week = $mpmw; planning date = $plandate";
print STDERR "$sn: ephemeris and SAA file names are:\n...$ephemfiletrunc\n...$saafiletrunc\n";

print STDERR "$sn: ephemeris file mission days: $ead $ebd; SAA file days: $sad $sbd\n";
printf STDERR "$sn: WARNING: ATS plan date - ephemeris file delivery date = %d days, not ~10 days\n",$ldp-$ead if (abs($ldp-$ead-10) > 2);
printf STDERR "$sn: WARNING: ATS plan date - ephemeris file product date = %d days, not ~10 days\n",$ldp-$ebd if (abs($ldp-$ebd-10) > 2);
printf STDERR "$sn: WARNING: ATS plan date - SAA report delivery date = %d days, not ~10 days\n",$ldp-$sad if (abs($ldp-$sad-10) > 2);
printf STDERR "$sn: WARNING: ATS plan date - SAA report product date = %d days, not ~10 days\n",$ldp-$sbd if (abs($ldp-$sbd-10) > 2);

# GLAST Ephemeris file format: 
#"Time (UTCJFOUR)" "x (km)" "y (km)" "z (km)" "Lat (deg)" "Lon (deg)" "RightAscension (deg)" "Declination (deg)"
#163/2012 00:00:00.000 -6840.442281 399.925898 -961.152656 -8.105 -82.920 -96.854 24.141
#163/2012 00:01:00.000 -6875.211768 -13.618436 -772.774322 -6.524 -79.710 -92.750 24.659

# GLAST SAA report file format: 
#"Start Time (UTCJFOUR)","Start Pass","Stop Time (UTCJFOUR)","Stop Pass","Duration (min)"
#163/2012 00:00:00.000,"22026",163/2012 00:03:03.692,"22026",3.062
#163/2012 08:46:26.264,"22032",163/2012 09:00:19.699,"22032",13.891

# define various pad times and window times used in constructing ATS commands
$postsaa = 2700; # minimum seconds after SAA exit when an Ascending Node cannot have LPA stop and start
$biaspadtime = 5; # pad time after SAA exit for LATBIASVUP command
$anpadtime = 5; # pad time either side of Ascending Node for LPA stop and start
$saapadtime = 30; # time outside SAA for LPA stop and start
$extra = 2;  # INTEGER HOURS of time before the start and after the end of the mission week to include in the ATS

# make hash table of cumulative day count keyed by Fermi mission week
# need unix time (seconds since start of 1970 UTC) for 2008 May 29 = Fermi Mission Week 0
$t_mw0 = 1212019200;
for $week (0..1000) {
    $t_mw = $t_mw0 + $week*604800;
    ($dum,$dum,$dum,$dum,$dum,$year,$dum,$doy,$dum) = gmtime($t_mw);
    $year += 1900;
    $doy++;
    $doy{$week} = $doy;
    $week{$week} = $daycount{$year}+$doy;
    $year{$week} = $year;
    $s_mw{$week} = $week{$week}*86400;
}

# check and open input files

open (EF, "<", $ephemfile) or die "$sn: Could not open the GLAST ephemeris file:\n $ephemfile";
open (SF, "<", $saafile) or die "$sn: Could not open the SAA report file:\n $saafile";
open (OF, ">", $outfile) or die "$sn: Could not open the output file: $outfile\n";

# get day range for the mission week

$day0 = $week{$mpmw} - 1;
$day2 = $day0 + 2;
$day8 = $day0 + 8;

# read GLAST Ephemeris file

while (<EF>) {
    next if (/Time/);
    @field = split;
    ($day, $year) = split('/',$field[0]);
    $daynum = $daycount{$year} + $day;
    last if ($daynum > $day8);
    next if ($daynum < $day0);
    ($hour, $minute, $second) = split(':',$field[1]);
    last if ($daynum == $day8 and $hour >= $extra);
    next if ($daynum == $day0 and $hour < (24-$extra));
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    push @ephemtime,$time;
    push @zposition,$field[4];
}

# read GLAST SAA report file
# collect SAA transits outside the mission week, to avoid
# scheduling incorrect run stop and start at an AN at the start
# of the week, during a daily SAA season
while (<SF>) {
    next if (/Time/);
    s/,/ /g;
    @field = split;
    ($day, $year) = split('/',$field[0]);
    $daynum = $daycount{$year} + $day;
    last if ($daynum > $day8);
    next if ($daynum < $day0);
    ($hour, $minute, $second) = split(':',$field[1]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    push @saatimeinextra,$time;
    ($day, $year) = split('/',$field[3]);
    $daynum = $daycount{$year} + $day;
    ($hour, $minute, $second) = split(':',$field[4]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    push @saatimeoutextra,$time;
    ($day, $year) = split('/',$field[0]);
    $daynum = $daycount{$year} + $day;
    ($hour, $minute, $second) = split(':',$field[1]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    last if ($daynum == $day8 and $hour >= $extra);
    next if ($daynum == $day0 and $hour < (24-$extra));
    $run{$time} = "Se end";
    ($day, $year) = split('/',$field[3]);
    $daynum = $daycount{$year} + $day;
    ($hour, $minute, $second) = split(':',$field[4]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    $run{$time} = "Sx beg"; 
}

# find times of ascending node crossings, that occur outside the SAA
# but not later than $SAAPAD seconds before an SAA entry
# and not earlier than $SAALAG seconds after an SAA exit

foreach $i (1..$#zposition) {
    next unless ($zposition[$i-1] <= 0 and $zposition[$i] >= 0);
    $fraction = 0 - $zposition[$i-1]/($zposition[$i]-$zposition[$i-1]);
    $timestep = $ephemtime[$i] - $ephemtime[$i-1];
    $deltatime = int($fraction * $timestep);
    $time = $ephemtime[$i-1] + $deltatime;
    $bad = 0;
    foreach $j (0..$#saatimeinextra) {
        $bad = 1 if ($time >= ($saatimeinextra[$j]-$saapadtime) and $time <= ($saatimeoutextra[$j]+$postsaa));
    }
    $run{$time+$anpadtime} = "Ax beg" unless ($bad);
    $run{$time-$anpadtime} = "Ae end" unless ($bad);
}

# define time-ordered list of alternating run starts and stops
@times = sort { $a <=> $b } keys %run;
shift(@times) if ($run{$times[0]} =~ /end/);
#pop(@times) if ($run{$times[-1]} =~ /beg/);

$runbase = "Acquisition,NORMAL,InReview,Unknown,[$mpmw] Normal acquisition (default configuration)";

# print ATS header lines
print STDERR "$sn: output goes to $outfile\n";
$runtime = `date -u +"%s %F %Y/%j:%T UTC"`;
chomp $runtime;
$head1 = "$sn: LAT weekly Planned comparison product generated at $runtime for MW $mpmw;";
$head2 = "ATS timespan: $year{$mpmw}/$doy{$mpmw}:00:00:00 to $year{$mpmw+1}/$doy{$mpmw+1}:00:00:00;";
print OF "$head1 $head2\n";
print OF "#Data products used: $ephemfilename $saafilename\n";
print OF "Start Time,End Time,Type,Priority,State,Status,Description\n";

foreach $tt (@times) {
    $event = $run{$tt};
    if ($event =~ /beg/) {
	$tx = $tt;
	$eventx = $event;
	next;
    }
    $begtime = ($eventx =~ /Sx/)? $tx + $biaspadtime : $tx;
    $endtime = ($event =~ /Se/)? $tt - $saapadtime : $tt;
    next if ($endtime < ($s_mw{$mpmw}-30));
    last if ($begtime > ($s_mw{$mpmw+1}+30));
    $tbeg = formtime($begtime);
    $tend = formtime($endtime);
    $run = "$tbeg,$tend,$runbase\n";
    if ($begtime < ($s_mw{$mpmw}-30)) { 
        print STDERR "$sn: omitting the run at the MW start ($tbeg - $tend), like the MPT plan\n";
        next;
    }
    $lines{$begtime} = $run;
}

# define output line for weekly LRASTATSEND command at 00:00:00 Friday
$time = $day2*86400;
while ($lines{$time}) { $time++ };
$t0 = formtime($time);
$lines{$time} = "$t0,$t0,ATSList,NORMAL,InReview,Unknown,[$mpmw] Dump LRA Statistics Block to SSR (MPLAN-21)\n";

# define output line for weekly 3 LMEMDUMPMEM commands at 01:00:00 Friday
$time = $day2*86400 + 3600;
$t0 = formtime($time);
$t1 = formtime($time+2*60);
$lines{$time} = "$t0,$t1,ATSList,NORMAL,InReview,Unknown,[$mpmw] Dump SUROM to SSR (MPLAN-22)\n";

@times = sort { $a <=> $b } keys %lines;
foreach (@times) { 
    print OF $lines{$_};
}
close OF;

##***************************************************************************
sub formtime {
##***************************************************************************

# convert a time in seconds since 2008-05-29 to the time format used in the ATS

    my $time = shift;

    ($s,$m,$h,$mday,$mon,$yr,$dum,$dum,$dum) = gmtime($time+1212019200-150*86400);
    $timeform = sprintf "%04d-%02d-%02d %02d:%02d:%02d",$yr+1900,$mon+1,$mday,$h,$m,$s;

    return $timeform;    
}
