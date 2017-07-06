#!/usr/local/bin/perl -w

# report Ascending Node times from the latest Fermi ephemeris file.
# indicate ANs which could be used for valid LAT LPA run boundaries,
# by crosschecking with the latest SAA predict file.

# Robert Cameron
# 2016 October

use File::Basename;
$sn = basename($0);

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

$mproot = "/u/gl/rac/LATmetrics/planning";

# find the latest GLAST ephemeris filename and path, at the end of the file $mproot/EPHEM.files
$ephemfile = `tail -1 $mproot/EPHEM.files`;
chomp $ephemfile;

# find the latest SAA report filename and path, at the end of the file $mproot/../saa/SAA.reports
$saafile = `tail -1 $mproot/../saa/SAA.reports`;
chomp $saafile;

@f = split ("/",$ephemfile);
print STDERR "$sn: using ephemeris file $f[-1]\n";

@f = split ("/",$saafile);
print STDERR "$sn: using SAA report file $f[-1]\n";
       
# GLAST Ephemeris file format: 
#"Time (UTCJFOUR)" "x (km)" "y (km)" "z (km)" "Lat (deg)" "Lon (deg)" "RightAscension (deg)" "Declination (deg)"
#163/2012 00:00:00.000 -6840.442281 399.925898 -961.152656 -8.105 -82.920 -96.854 24.141
#163/2012 00:01:00.000 -6875.211768 -13.618436 -772.774322 -6.524 -79.710 -92.750 24.659

# GLAST SAA report file format: 
#"Start Time (UTCJFOUR)","Start Pass","Stop Time (UTCJFOUR)","Stop Pass","Duration (min)"
#163/2012 00:00:00.000,"22026",163/2012 00:03:03.692,"22026",3.062
#163/2012 08:46:26.264,"22032",163/2012 09:00:19.699,"22032",13.891

# define pad times and window time used in constructing ATS commands
$postsaatime = 2700; # minimum seconds after SAA exit when an Ascending Node cannot have LPA stop and start
$saapadtime = 30; # time outside SAA for LPA stop and start

# check and open input files

open (EF, "<", $ephemfile) or die "$sn: Could not open the GLAST ephemeris file:\n $ephemfile";
open (SF, "<", $saafile) or die "$sn: Could not open the SAA report file:\n $saafile";

# read GLAST Ephemeris file

while (<EF>) {
    next if (/Time/);
    next unless (/20/);
    @field = split;
    ($day, $year) = split('/',$field[0]);
    $daynum = $daycount{$year} + $day;
    ($hour, $minute, $second) = split(':',$field[1]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    push @ephemtime,$time;
    push @zposition,$field[4];
}

# read GLAST SAA report file

while (<SF>) {
    next if (/Time/);
    next unless (/20/);
    s/,/ /g;
    @field = split;
    ($day, $year) = split('/',$field[0]);
    $daynum = $daycount{$year} + $day;
    ($hour, $minute, $second) = split(':',$field[1]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    push @saatimeinextra,$time;
    ($day, $year) = split('/',$field[3]);
    $daynum = $daycount{$year} + $day;
    ($hour, $minute, $second) = split(':',$field[4]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    push @saatimeoutextra,$time;
}

# find times of ascending node crossings, that occur outside the SAA
# but not later than $SAAPAD seconds before an SAA entry
# and not earlier than $SAALAG seconds after an SAA exit

foreach $i (1..$#zposition) {
    next unless ($zposition[$i-1] <= 0 and $zposition[$i] >= 0);
    $fraction = 0 - $zposition[$i-1]/($zposition[$i]-$zposition[$i-1]);
    $timestep = $ephemtime[$i] - $ephemtime[$i-1];
    $deltatime = int($fraction * $timestep);
    $ANtime = $ephemtime[$i-1] + $deltatime;
    $ANdate = formtime($ANtime);
    $bad = "";
    foreach $j (0..$#saatimeinextra) {
        $bad = "SAA" if ($ANtime >= ($saatimeinextra[$j]-$saapadtime) and $ANtime <= ($saatimeoutextra[$j]+$postsaatime));
    }
    print "$ANdate $bad\n";
}

##***************************************************************************
sub formtime {
##***************************************************************************

# convert a time in seconds since 2008-05-29 to the time format used in the ATS

    my $time = shift;

    ($s,$m,$h,$mday,$mon,$yr,$dum,$dum,$dum) = gmtime($time+1212019200-150*86400);
    $timeform = sprintf "%04d-%02d-%02d %02d:%02d:%02d",$yr+1900,$mon+1,$mday,$h,$m,$s;

    return $timeform;    
}
