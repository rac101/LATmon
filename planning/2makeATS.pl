#!/usr/local/bin/perl -w

# make a routine weekly LAT ATS
# this script is designed to be run on Mondays, in the late morning
# assume the MOC has FastCopied needed products to the ISOC already
# needed planning products are: 
#       1. GLAST ephemeris file
#       2. SAA report file

# Robert Cameron
# 2016 March

use Getopt::Long;
use File::Basename;

$sn = basename($0);

my $force = 0;
my $ofile = 0;
GetOptions ("force" => \$force, # flag: 1 = run to completion even if dates are wrong or outfile exists
            "ofile" => \$ofile) # flag: 1 = send output to a file with name starting with MW
    or die("$sn: Error in command line arguments\n");

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
#$ddays += 7 if ($today > 4);   # comment out this line if running very late in the mission week
$planydoy = `date -u --date="+$ddays days" +"%Y %j"`;
$plandate = `date -u --date="+$ddays days" +"%F DOY %j"`;
($py,$pdoy) = split (" ",$planydoy);
$ldp = $daycount{$py} + $pdoy;
$ld0 = $daycount{2008} + 150; # mission week 0 = 2008-5-29, 2008 DOY 150
$mpmw = ($ldp - $ld0)/7;

# define output filename
$mproot = "/u/gl/rac/LATmetrics/planning";
$outfile = "$mproot/$mpmw.ats2fake" if ($ofile);
exit if ($ofile and -e ($outfile) and !$force);

# find the latest GLAST ephemeris filename and path, at the end of the file $mproot/EPHEM.files
$ephemfile = `tail -1 $mproot/EPHEM.files`;
chomp $ephemfile;

# find the latest SAA report filename and path, at the end of the file $mproot/../saa/SAA.reports
$saafile = `tail -1 $mproot/../saa/SAA.reports`;
chomp $saafile;

# next check the dates of when the files were received at the ISOC and the dates in the file names
# to verify that the files are not too old. Typical filenames and paths are of the form:
# where $FCOPY = /nfs/farm/g/glast/u23/ISOC-flight/Archive
# $FCOPY/2016/01/004.01.04.Mon/utc14/14.42.21/MOC_2016004094203/GLAST_EPH_2016004_2016064_00.txt
# $FCOPY/2016/01/004.01.04.Mon/utc14/14.44.44/MOC_2016004094431/L2016004SAA.00

@f = split("/",$ephemfile);
($junk,$ephemfiletrunc) = split("fcopy",$ephemfile);
@g = split('\.',$f[11]);
$ead = $daycount{$f[9]} + $g[0];
$ephemfilename = $f[-1];
@g = split("_",$ephemfilename);
$ebd = $daycount{int($g[2]/1000)} + ($g[2] % 1000);

@f = split("/",$saafile);
($junk,$saafiletrunc) = split("fcopy",$saafile);
@g = split('\.',$f[11]);
$sad = $daycount{$f[9]} + $g[0];
$saafilename = $f[-1];
$f[-1] =~ /L(\d+)SAA.*/;
$sbd = $daycount{int($1/1000)} + ($1 % 1000);

$ephemfiletrunc =~ s/GLAST_EPH_20/\n   GLAST_EPH_20/;
$saafiletrunc =~ s/L20/\n   L20/;

exit if ((abs($ldp-$ead-10) > 2) or (abs($ldp-$ebd-10) > 2) or (abs($ldp-$sad-10) > 2) or (abs($ldp-$sbd-10) > 2) and !$force);
print STDERR "$sn: today = $weekday = $ldnow; ATS planning day = $ldp\n";
print STDERR "$sn: planning Mission Week = $mpmw; date = $plandate";
print STDERR "$sn: ephemeris and SAA files are:\n...$ephemfiletrunc\n...$saafiletrunc\n";
print STDERR "$sn: ephemeris file mission days: $ead $ebd; SAA file days: $sad $sbd\n";
printf STDERR "$sn: WARNING: ATS plan date - ephemeris file delivery date = %d days, not ~10 days\n",$ldp-$ead if (abs($ldp-$ead-10) > 2);
printf STDERR "$sn: WARNING: ATS plan date - ephemeris file product date = %d days, not ~10 days\n",$ldp-$ebd if (abs($ldp-$ebd-10) > 2);
printf STDERR "$sn: WARNING: ATS plan date - SAA report delivery date = %d days, not ~10 days\n",$ldp-$sad if (abs($ldp-$sad-10) > 2);
printf STDERR "$sn: WARNING: ATS plan date - SAA report product date = %d days, not ~10 days\n",$ldp-$sbd if (abs($ldp-$sbd-10) > 2);

print STDERR "$sn: using 0 for runID and tranID values\n";

# define part of default LPASTART command
$lpa0 = "( LPALATCCFGID=0xffffffff, LPALATCIGNID=0xffffffff, LPARUNID=0, LPADBID=0x0, LPAMODEID=0x0, LPALATCCNSFLG=0x1, LPACPUS=0x6 );";

# define various pad times and window times used in constructing ATS commands
$window = 60; # seconds of time window around orbital events in ATS lines
$postsaa = 2700; # minimum seconds after SAA exit when an Ascending Node cannot have LPA stop and start
$biaspadtime = 5; # pad time after SAA exit for LATBIASVUP command
$biaspad = "000:00:00:05"; # DAY:HH:MM:SS pad time after SAA exit for LATBIASVUP command
$anpadtime = 5; # pad time either side of Ascending Node for LPA stop and start
$anpad = "000:00:00:05"; # DAY:HH:MM:SS pad time either side of Ascending Node for LPA stop and start
$saapadtime = 30; # time outside SAA for LPA stop and start
$saapad = "000:00:00:$saapadtime";

# make hash table of cumulative day count keyed by Fermi mission week
# need unix time (seconds since start of 1970 UTC) for 2008 May 29 = Fermi Mission Week 0
# also indentify times for the start and end of the MW
$t_mw0 = 1212019200;
for $week (0..1000) {
    $t_mw = $t_mw0 + $week*604800;
    ($dum,$dum,$dum,$dum,$dum,$year,$dum,$doy,$dum) = gmtime($t_mw);
    $year += 1900;
    $doy++;
    $doy{$week} = $doy;
    $week{$week} = $daycount{$year}+$doy;
    $year{$week} = $year;
}

# check and open input files

open (EF, "<", $ephemfile) or die "$sn: Could not open the GLAST ephemeris file:\n $ephemfile";
open (SF, "<", $saafile) or die "$sn: Could not open the SAA report file:\n $saafile";

# get day and seconds range for the mission week

$s_mw1 = $week{$mpmw} * 86400;
$s_mw2 = $s_mw1 + 604800;
$day0 = $week{$mpmw} - 1;
$day2 = $day0 + 2;
$day8 = $day0 + 8;

# GLAST Ephemeris file format: 
#"Time (UTCJFOUR)" "x (km)" "y (km)" "z (km)" "Lat (deg)" "Lon (deg)" "RightAscension (deg)" "Declination (deg)"
#163/2012 00:00:00.000 -6840.442281 399.925898 -961.152656 -8.105 -82.920 -96.854 24.141
#163/2012 00:01:00.000 -6875.211768 -13.618436 -772.774322 -6.524 -79.710 -92.750 24.659
# read GLAST Ephemeris file

while (<EF>) {
    next if (/Time/);
    @field = split;
    ($day, $year) = split('/',$field[0]);
    $daynum = $daycount{$year} + $day;
    last if ($daynum > $day8);
    next if ($daynum < $day0);
    ($hour, $minute, $second) = split(':',$field[1]);
    last if ($daynum == $day8 and $hour >= 1);
    next if ($daynum == $day0 and $hour < 23);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
    push @ephemtime,$time;
    push @zposition,$field[4];
}

# GLAST SAA report file format: 
#"Start Time (UTCJFOUR)","Start Pass","Stop Time (UTCJFOUR)","Stop Pass","Duration (min)"
#163/2012 00:00:00.000,"22026",163/2012 00:03:03.692,"22026",3.062
#163/2012 08:46:26.264,"22032",163/2012 09:00:19.699,"22032",13.891
# read GLAST SAA report file
# collect SAA transits outside the mission week, to avoid
# scheduling incorrect run stop and start at an AN at the start
# of the week, during a daily SAA season
while (<SF>) {
    next unless (/2/);
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
    last if ($daynum == $day8 and $hour >= 1);
    next if ($daynum == $day0 and $hour < 23);
# check time against MW boundary times
    print STDERR "$sn: WARNING! SAA entry within 1 minute of the start of MW $mpmw\n" if (abs($time - $s_mw1) < 60);
    print STDERR "$sn: WARNING! SAA entry within 1 minute of the end of MW $mpmw\n" if (abs($time - $s_mw2) < 60);
    push @saatimein,$time;
    push @runtime,$time;
    ($day, $year) = split('/',$field[3]);
    $daynum = $daycount{$year} + $day;
    ($hour, $minute, $second) = split(':',$field[4]);
    $time = $daynum*86400 + $hour*3600 + $minute*60 + $second;
# check time against MW boundary times
    print STDERR "$sn: WARNING! SAA exit within 1 minute of the start of MW $mpmw\n" if (abs($time - $s_mw1) < 60);
    print STDERR "$sn: WARNING! SAA exit within 1 minute of the end of MW $mpmw\n" if (abs($time - $s_mw2) < 60);
    push @saatimeout,$time;
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
# check time against MW boundary times
    print STDERR "$sn: WARNING! Ascending Node within 1 minute of the start of MW $mpmw\n" if (abs($time - $s_mw1) < 60);
    print STDERR "$sn: WARNING! Ascending Node within 1 minute of the end of MW $mpmw\n" if (abs($time - $s_mw2) < 60);
    push @ascnode,$time unless ($bad);
    push @runtime,$time unless ($bad);
}

# define ATS lines for each SAA
foreach $i (0..$#saatimein) {
    $saatime = $saatimein[$i];
    $t0 = formtime($saatime-$window);
    $t1 = formtime($saatime+$window);
    $base = "IF ( LAT_SAA && AbsStart >= $t0 && AbsStart <= $t1 ) THEN AT";
    $ats = "$base START DO\n-$saapad\tCMD\tLPASTOP;\n";
    $keytime = $saatime - $saapadtime;
    $lines{$keytime} = $ats;
    $ats = "$base STOP DO\n$biaspad\tACT\tLATBIASVUP;\n";
    $time = $saatimeout[$i];
    $keytime = $time + $biaspadtime;
    $lines{$keytime} = $ats;
    $ats = "$base STOP DO\n$saapad\tCMD\tLPASTART\t$lpa0\n";
    $keytime = $time + $saapadtime;
    $lines{$keytime} = $ats;
}

# define ATS lines for each Ascending Node
foreach $i (0..$#ascnode) {
    $antime = $ascnode[$i];
    $t0 = formtime($antime-$window);
    $t1 = formtime($antime+$window);
    $base = "IF ( ASCENDINGNODE && AbsStart >= $t0 && AbsStart <= $t1 ) THEN AT";
    $ats = "$base START DO\n-$anpad\tCMD\tLPASTOP;\n";
    $keytime = $antime - $anpadtime;
    $lines{$keytime} = $ats;
    $ats = "$base STOP DO\n$anpad\tCMD\tLPASTART\t$lpa0\n";
    $keytime = $antime + $anpadtime;
    $lines{$keytime} = $ats;
}

# define ATS line for weekly LRASTATSEND command at 00:00:00 Friday
$time = $day2*86400;
while ($lines{$time}) { $time++ };
$t0 = formtime($time);
$lines{$time} = "$t0\tCMD\tLRASTATSEND;\n";

# define ATS lines for weekly 3 LMEMDUMPMEM commands at 01:00:00 Friday
# use the mission week number to generate memory transaction IDs
$base = ", LMEMDEST=1, LMEMADDRESSHI=0xFFF0, LMEMADDRESSLO=0, LMEMSIZEHI=1, LMEMSIZELO=0 );";
$time = $day2*86400 + 3600;
$t0 = formtime($time);
$lines{$time} = "$t0\tCMD\tLMEMDUMPMEM\t( LMEMLATUNIT=0, LMEMTRANID=0$base\n";
$time += 60;
$t0 = formtime($time);
$lines{$time} = "$t0\tCMD\tLMEMDUMPMEM\t( LMEMLATUNIT=1, LMEMTRANID=1$base\n";
$time += 60;
$t0 = formtime($time);
$lines{$time} = "$t0\tCMD\tLMEMDUMPMEM\t( LMEMLATUNIT=2, LMEMTRANID=2$base\n";

# print results to OUTPUT

$ofsuccess = 0;
if ($ofile) { $ofsuccess = open( $outf , '>', $outfile ) };
$outf = *STDOUT unless $ofsuccess;
print STDERR "$sn: output going to $outfile\n" if ($ofsuccess);

# print ATS header lines
$runtime = `date -u +"%s %F %Y/%j:%T UTC"`;
chomp $runtime;
$head1 = "$sn: LAT weekly ATS generated at $runtime;";
$head2 = "ATS timespan: $year{$mpmw}/$doy{$mpmw}:00:00:00 to $year{$mpmw+1}/$doy{$mpmw+1}:00:00:00;";
$head3 = "LAT ATS version FAKE for mission week $mpmw;";
print $outf "$head1 $head2 $head3\n";
print $outf "//\n";
print $outf "// Data products used:\n";
print $outf "// $ephemfilename\n";
print $outf "// $saafilename\n";
print $outf "//\n";

# print body of ATS
@key = sort { $a <=> $b } keys %lines;
foreach (@key) { print $outf $lines{$_} if (($_ >= $s_mw1) && ($_ <= $s_mw2)) };
close $outf if ($ofile and $ofsuccess);

##***************************************************************************
sub formtime {
##***************************************************************************

# convert a time in linear seconds to the time format used in the ATS

    my $time = shift;

    my $day = int($time/86400);
    foreach $j (1..$#daycount) {
        $year = $year[$j-1];
        $dayzero = $daycount[$j-1];
        last if ($day > $daycount[$j-1] and $day <= $daycount[$j]);
    }
    $doy = $day - $dayzero;
    $hour = int(($time % 86400)/3600);
    $minute = int(($time % 3600)/60);
    $second = int($time % 60);
    $timeform = sprintf "$year/%03d:%02d:%02d:%02d",$doy,$hour,$minute,$second;

    return $timeform;
}
