#!/usr/local/bin/perl

# analyse and summarize daily uptime numbers collected using Jana's Uptime.py script
# do a better job of measuring uptime over the days in the input file

# Robert Cameron
# December 2014

use Time::Local;
use Time::JulianDay;

# usage: ./maddup.pl < tup.out
# usage: ./maddup.pl < tup.int

#t0 t1 Total TERMINAL QUIESCENT CALIBRATION DIAGNOSTIC PHYSICS PHYSICS_SAA TOO TOO_SAA ARR ARR_SAA HOLD BOOT OFF SAA IDLE RUNNING STOPPING UNKNOWN IDLE RUNNING STOPPING UNKNOWN 
#                                                                    LIM Mode Summary-----------------'
# 2008-07-30 23:59:55.340094 2008-08-01 00:00:04.340101 86408.000006 89.323223 19990.811864 0 0 41980.099320 0 0 0 180.540356 0 0 0 0 34375.260756 20342.698928 41959.864189 20.233290 0 62322.800066 0 0 0 
# 2008-07-31 23:59:55.340101 2008-08-02 00:00:04.340073 86407.999970 0 0 0 0 0 0 0 0 0 0 0 0 0 86407.999970 0 0 0 0 0 0 0 0 

# time fields: 
#  4 total
#  5 terminal
#  6 quiescent
#  7 calibration
#  8 diagnostic
#  9 physics
# 10 physics in SAA
# 11 ToO
# 12 ToO in SAA
# 13 ARR
# 14 ARR in SAA
# 15 hold
# 16 boot
# 17 off (how is that known from telemetry?)
# 18 SAA mode
# 19 LPA idle
# 20 LPA running
# 21 LPA stopping 
# 22 LPA unknown
# 23 LCI idle 
# 24 LCI running
# 25 LCI stopping
# 26 LCI unknown

$jd2008 = julian_day(2008,8,4); # julian day for 4 August 2008
$s1970 = `date +%s`;
$jdnow = local_julian_day($s1970);
$mission_days = $jdnow - $jd2008;
$misec = $mission_days*86400;
print $jdnow-$jd2008, " mission days since 2008 August 4 = $misec mission seconds\n\n";
#open( TUP, "tup.int" ) or die "$0: Cannot open input file 'tup.int'\n";
@days = ();
@timed = ();
while (<>) {
    next unless /20/;
    next if /#/;
#    next if /2008-07/;
    @f = split;
    if ($f[1] =~ /^23:5/) {
	($year,$mon,$day) = split(/-/,$f[0]);
#	print "\n$f[0] $f[1] year $year month $mon day $day\n";
	$time = timegm(0,0,0,$day,$mon-1,$year-1900);
	($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = gmtime($time + 86400 + 3600);
	$f[0] = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$day;
	$f[1] = "";
    }
    push @days,$f[0];
    push @timed,$time;
    @k = @f;
    $f[1] =~ s/\..*//;
    $f[3] =~ s/\..*//;
    $k[4] = sprintf "%4.1f",$k[4]/1000;
    for $i (5..26) { $k[$i] = sprintf "%2d", $k[$i]/1000 };
#    print "$f[0] $f[1] $k[4] $k[5] $k[6] $k[7] $k[8] $k[9] $k[10] $k[11] $k[12] $k[13] $k[14] $k[15] $k[16] $k[17] $k[18] $k[19] $k[20] $k[21] $k[22] $k[23] $k[24] $k[25] $k[26]\n";
    unless ($f[4]) { print "$0: skipping line starting with $f[0] $f[1]\n"; next };
    $day_ctr++;
    $norm = 1.0;
    if ($f[4] > 86400.0) { $norm = 86400.0/$f[4] };
    $tot += $f[4]*$norm;
    $ter += $f[5]*$norm;
    $qui += $f[6]*$norm;
    $cal += $f[7]*$norm;
    $dia += $f[8]*$norm;
    $phy += $f[9]*$norm;
    $phy_saa += $f[10]*$norm;
    $too += $f[11]*$norm;
    $too_saa += $f[12]*$norm;
    $arr += $f[13]*$norm;
    $arr_saa += $f[14]*$norm;
    $hold += $f[15]*$norm;
    $boot += $f[16]*$norm;
    $off += $f[17]*$norm;
    $saa += $f[18]*$norm;
    $lpa_idl += $f[19]*$norm;
    $lpa_run += $f[20]*$norm;
    $lpa_stop += $f[21]*$norm;
    $lpa_unk += $f[22]*$norm;
    $lci_idl += $f[23]*$norm;
    $lci_run += $f[24]*$norm;
    $lci_stop += $f[25]*$norm;
    $lci_unk += $f[26]*$norm;
}

printf "First and last counted days in the input = $days[0] $days[-1]\n";
$spand = ($timed[-1] - $timed[0])/86400;
printf "Span from first to last counted days in the input = $spand\n"; 
printf "Day count from the input = %d (NOTE: %d days*86400 = %d seconds)\n",$day_ctr,$day_ctr,$day_ctr*86400;
printf "Total time = %d\n",$tot;
printf "Terminal time = %d    Quiescent time = %d     Calibration time = %d     Diagnostic time = %d\n",$ter,$qui,$cal,$dia;
printf "Physics time = %d     Physics time in SAA = %d\n",$phy,$phy_saa;
printf "ToO time = %d         ToO time in SAA = %d\n",$too,$too_saa;
printf "ARR time = %d         ARR time in SAA = %d\n",$arr,$arr_saa;
printf "Hold time = %d       Boot time = %d     Off time = %d    SAA time = %d\n",$hold,$boot,$off,$saa;
printf "LPA: idle time = %d    run time = %d    stop time = %d    unknown time = %d\n",$lpa_idl,$lpa_run,$lpa_stop,$lpa_unk;
printf "LCI: idle time = %d    run time = %d  stop time = %d    unknown time = %d\n",$lci_idl,$lci_run,$lci_stop,$lci_unk;

# now calculate some numbers of interest
print "\n\n";
printf "LAT uptime fraction (LCI idle time/Total time) = %7.4f\n",($lci_idl)/$tot;
printf "LAT uptime fraction (LCI idle time/Mission time) = %7.4f\n",($lci_idl)/$misec;
printf "LAT uptime fraction (LCI idle+run+stop time/Total time) = %7.4f\n",($lci_idl+$lci_run+$lci_stop)/$tot;
printf "LAT uptime fraction (LCI idle+run+stop time/Mission time) = %7.4f\n",($lci_idl+$lci_run+$lci_stop)/$misec;
printf "LAT uptime fraction (LPA idle+run+stop + LCI run+stop time/Total time) = %7.4f\n",($lpa_idl+$lpa_run+$lpa_stop+$lci_run+$lci_stop)/$tot;
printf "LAT uptime fraction (LPA idle+run+stop + LCI run+stop time/Mission time) = %7.4f\n",($lpa_idl+$lpa_run+$lpa_stop+$lci_run+$lci_stop)/$misec;
printf "LAT uptime fraction (LPA idle+run+stop time/Total time) = %7.4f\n",($lpa_idl+$lpa_run+$lpa_stop)/$tot;
printf "LAT uptime fraction (LPA idle+run+stop time/Mission time) = %7.4f\n",($lpa_idl+$lpa_run+$lpa_stop)/$misec;
printf "LAT useful time fraction (LPA run+stop + LCI run+stop/Total time) = %7.4f\n",($lpa_run+$lpa_stop+$lci_run+$lci_stop)/$tot;
printf "LPA fraction (LPA run time/Total time) = %7.4f\n",($lpa_run)/$tot;
printf "LPA fraction (LPA run+stop time/Total time) = %7.4f\n",($lpa_run+$lpa_stop)/$tot;
printf "LPA effective fraction (LPA run+stop time+SAA time/Total time) = %7.4f\n",($lpa_run+$lpa_stop+$saa)/$tot;
printf "LCI fraction (LCI run+stop time/Total time) = %8.5f\n",($lci_run+$lci_stop)/$tot;
printf "LCI effective fraction (LCI run+stop time+SAA time/Total time) = %8.5f\n",($lci_run+$lci_stop+$saa)/$tot;
printf "LPA+LCI effective time fraction (LPA run+stop + LCI run+stop + SAA time/Total time) = %7.4f\n",($lpa_run+$lpa_stop+$lci_run+$lci_stop+$saa)/$tot;
printf "Fractional time lost to SAA (SAA time/Total time) = %7.4f\n",$saa/$tot;
printf "Physics time/Total time = %7.4f\n",$phy/$tot;
printf "Physics time/LPA run time = %7.4f\n",$phy/$lpa_run;
