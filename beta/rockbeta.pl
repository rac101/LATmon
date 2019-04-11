#!/usr/local/bin/perl -w

# calculate the beta angle and rock angle for Fermi
# from Fermi posiiton and velocity telemetry and attitude quaternion telemetry
# here is the format of the MnemRet.py command:
# MnemRet.py -b '2018-07-30 00:00:00' -e '+1 seconds' SG_NAVPOSJ2000_1 SG_NAVPOSJ2000_2 SG_NAVPOSJ2000_3 SG_NAVVELJ2000_1 SG_NAVVELJ2000_2 SG_NAVVELJ2000_3 SG_QBI1 SG_QBI2 SG_QBI3 SG_QBI4
#
# which produces the output:
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_NAVPOSJ2000_1       1011723.187500000000 (      1011723.187500000000)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_NAVPOSJ2000_2       6675293.000000000000 (      6675293.000000000000)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_NAVPOSJ2000_3      -1433977.750000000000 (     -1433977.750000000000)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_NAVVELJ2000_1         -6837.290039062500 (        -6837.290039062500)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_NAVVELJ2000_2          1656.941772460938 (         1656.941772460938)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_NAVVELJ2000_3          2894.486083984375 (         2894.486083984375)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_QBI1                      0.410779782616 (            0.410779782616)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_QBI2                      0.861714590390 (            0.861714590390)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_QBI3                      0.195988977178 (            0.195988977178)
#VAL: 2018-07-30 00:00:00.140071 (1532908800.140071) SG_QBI4                     -0.224268267322 (           -0.224268267322)
#VAL: 2018-07-30 00:00:00.340072 (1532908800.340072) SG_QBI1                      0.410768172141 (            0.410768172141)
#VAL: 2018-07-30 00:00:00.340072 (1532908800.340072) SG_QBI2                      0.861704278076 (            0.861704278076)
#VAL: 2018-07-30 00:00:00.340072 (1532908800.340072) SG_QBI3                      0.195979914501 (            0.195979914501)
#VAL: 2018-07-30 00:00:00.340072 (1532908800.340072) SG_QBI4                     -0.224337065626 (           -0.224337065626)
#VAL: 2018-07-30 00:00:00.540070 (1532908800.540070) SG_QBI1                      0.410755555910 (            0.410755555910)
#VAL: 2018-07-30 00:00:00.540070 (1532908800.540070) SG_QBI2                      0.861694562135 (            0.861694562135)
#VAL: 2018-07-30 00:00:00.540070 (1532908800.540070) SG_QBI3                      0.195970456417 (            0.195970456417)
#VAL: 2018-07-30 00:00:00.540070 (1532908800.540070) SG_QBI4                     -0.224405737645 (           -0.224405737645)
#VAL: 2018-07-30 00:00:00.740071 (1532908800.740071) SG_QBI1                      0.410743835641 (            0.410743835641)
#VAL: 2018-07-30 00:00:00.740071 (1532908800.740071) SG_QBI2                      0.861684445755 (            0.861684445755)
#VAL: 2018-07-30 00:00:00.740071 (1532908800.740071) SG_QBI3                      0.195960125462 (            0.195960125462)
#VAL: 2018-07-30 00:00:00.740071 (1532908800.740071) SG_QBI4                     -0.224475046846 (           -0.224475046846)
#VAL: 2018-07-30 00:00:00.940068 (1532908800.940068) SG_QBI1                      0.410731361871 (            0.410731361871)
#VAL: 2018-07-30 00:00:00.940068 (1532908800.940068) SG_QBI2                      0.861674726320 (            0.861674726320)
#VAL: 2018-07-30 00:00:00.940068 (1532908800.940068) SG_QBI3                      0.195949379543 (            0.195949379543)
#VAL: 2018-07-30 00:00:00.940068 (1532908800.940068) SG_QBI4                     -0.224544550265 (           -0.224544550265)

# output to STDOUT (htr.history) will be
# YYYY-MM-DD HH:MM:SS R_geo Beta Rock Z_x Z_y Z_z

# Robert Cameron
# August 2018

# usage: ./rockbeta.pl >> rockbeta.history

use Math::Trig;

# Method: 
# 0. find set of hourly time stamps to do the following steps: 
# 1. get POS, VEL and Quaternion data from telemetry using MnemRet.py
# 2. get POS, VEL and Quaternion vectors for the same time tag.
# 3. get Rgeo from POS vector
# 4. get orbit pole vector from POS and VEL vectors
# 5. get Direction Cosine Matrix (DCM) from attitude Quaternion
# 6. get Z-axis vector from DCM
# 7. get signed rock angle from dot product between orbit pole vector and Z-axis vector
# 8. calculate Sun xyz vector from time-tag of the telemetry
# 9. get beta angle from dot product between Sun vector and orbit pole vector
# 10. write output to STDOUT

# this script truncates numbers in the output

$pi = 3.14159265359;

#JD at Unix time 0 = 2440587.5

# first, find the most recent good results in rockbeta.history

#######
#$wdir = "/u/gl/rac/LATmetrics/beta";

#@tail = ();
#$nlines = 0;
#until ($tail[0] and $tail[0] =~ /^20/) {
#    $nlines++;
#    @tail = `tail -$nlines $wdir/betarock.history`;
#}
#if ($nlines > 1) { print STDERR "$0: needed to tail $nlines lines in betarock.history\n" };
#@f = split(' ',$tail[0]);
#($tailhour,$junk,$junk) = split(':',$f[1]);
#$taildate = "$f[0] $tailhour:00:00";

$taildate = "2018-08-23 00:00:00";
#######

$taildate_s = `date -u --date="$taildate" +"%s"`;

# bring the output file "up to date", i.e. 2 days ago

$yesterday = `date --date="2 days ago" +"%F %T"`;
$yesterday_s = `date --date="2 days ago" +"%s"`;
chomp $yesterday_s;

$hours = int(($yesterday_s - $taildate_s)/3600);

if ($hours > 1) { print STDERR "$0: processing $hours hours from $taildate to $yesterday\n" };

@poskey = ('SG_NAVPOSJ2000_1','SG_NAVPOSJ2000_2','SG_NAVPOSJ2000_3');
@velkey = ('SG_NAVVELJ2000_1','SG_NAVVELJ2000_2','SG_NAVVELJ2000_3');
@quatkey = ('SG_QBI1', 'SG_QBI2', 'SG_QBI3', 'SG_QBI4');
$navec = '';
foreach (@poskey) { $navec .= " $_" };
foreach (@velkey) { $navec .= " $_" };
foreach (@quatkey) { $navec .= " $_" };


for $h (1..$hours) {
    ($junk,$junk,$hour,$mday,$mon,$year) = gmtime($taildate_s + $h*3600);
    $year += 1900;
    $mon++;
    $date = sprintf "%4d-%02d-%02d %02d:00:00",$year,$mon,$mday,$hour;
#    print STDERR "$0: running: $cmd\n";
    $cmd = "MnemRet.py -b '$date' -e '+1 seconds' $navec";
    @res = `$cmd`;
    unless (@res) { print STDERR "$0: no command result returned for time $date\n"; next };
    ($ymd,$hms,$sec,%hash) = cullres(@res);
    @keys = keys(%hash);
    if ($#keys != 9) {
	print STDERR "$0: did not get the expected 10 mnemonics at time $ymd $hms\n";
	next;
    }
    $rgeo = radius(%hash);
    @pole = orbpole(%hash);
    @z = quat_calc(%hash);
    $rock = rockangle(@pole,@z);
    $rock = sprintf "%.4f",$rock;
    @sun = sunvec($sec);
    $beta = beta(@pole,@sun);
    $beta = sprintf "%.4f",$beta;

# send results to STDOUT
    print "$ymd $hms $rgeo $rock $beta $z[0] $z[1] $z[2]\n";

}

sub sunvec {
    
# calculate Sun's geocentric position in ECI cartesian coordinates
    my $sec = shift;
    my $n = ($sec - 946728000)/86400.0; # $n = days since 2000 January 1 12:00:00 UTC
    $q = 280.460 + 0.98564736*$n; # $q = Sun mean longitude in degrees
    $g = 357.528 + 0.98560028*$n; # $g = mean anomaly in degrees
    $gr = $g *$pi/180.0; # $gr = mean anomaly in radians
    $e = 23.439 - 0.00000036*$n; # $e = obliquity of the ecliptic plane in degrees
    $er = $e * $pi/180.0; # $e = obliquity of the ecliptic plane in radians
    $L = $q + 1.915*sin($gr) + 0.020*sin(2*$gr); # $L = Geocentric apparent ecliptic longitude of the Sun in degrees
    $Lr = $L * $pi/180.0; # $Lr = Geocentric apparent ecliptic longitude of the Sun in radians
    $R = 1.00014 - 0.01671*cos($gr) - 0.00014*cos(2*$gr); # $R = Earth-Sun distance in astronomical units (AU)
    $R = 1.0;
    $Sunx = $R * cos($Lr); 
    $Suny = $R * cos($er) * sin($Lr); 
    $Sunz = $R * sin($er) * sin($Lr); 
    return ($Sunx, $Suny, $Sunz);
}

sub beta {

# calculate beta angle (complement of angle between Sun vector and Fermi's orbit pole)
    my ($ox,$oy,$oz,$Sunx,$Suny,$Sunz) = @_;
    $onorm = sqrt($ox*$ox + $oy*$oy + $oz*$oz);
    $oxn = $ox/$onorm;
    $oyn = $oy/$onorm;
    $ozn = $oz/$onorm;
    $Snorm = sqrt($Sunx*$Sunx + $Suny*$Suny + $Sunz*$Sunz);
    $Sxn = $Sunx/$Snorm;
    $Syn = $Suny/$Snorm;
    $Szn = $Sunz/$Snorm;

    $bdotprod = $oxn*$Sxn + $oyn*$Syn + $ozn*$Szn;
    $beta = 90 - acos($bdotprod)*180.0/$pi;
    return $beta;
}

sub rockangle {

# calculate Fermi rock angle (complement of angle between Fermi Z-axis and Fermi's orbit pole)
    my ($ox,$oy,$oz,$zx,$zy,$zz) = @_;
    $onorm = sqrt($ox*$ox + $oy*$oy + $oz*$oz);
    $oxn = $ox/$onorm;
    $oyn = $oy/$onorm;
    $ozn = $oz/$onorm;
    $znorm = sqrt($zx*$zx + $zy*$zy + $zz*$zz);
    $zxn = $zx/$znorm;
    $zyn = $zy/$znorm;
    $zzn = $zz/$znorm;

    $dotprod = $oxn*$zxn + $oyn*$zyn + $ozn*$zzn;
    $rock = 90 - acos($dotprod)*180.0/$pi;
    return $rock;
}

sub orbpole {

# calculate orbit pole vector in ECI cartesian coordinates
    my %h = @_;
    $px = $h{SG_NAVPOSJ2000_1};
    $py = $h{SG_NAVPOSJ2000_2};
    $pz = $h{SG_NAVPOSJ2000_3};
    $vx = $h{SG_NAVVELJ2000_1};
    $vy = $h{SG_NAVVELJ2000_2};
    $vz = $h{SG_NAVVELJ2000_3};
    $rmag = sqrt($px*$px + $py*$py + $pz*$pz);
    $vmag = sqrt($vx*$vx + $vy*$vy + $vz*$vz);
    $px /= $rmag;
    $py /= $rmag;
    $pz /= $rmag;
    $vx /= $vmag;
    $vy /= $vmag;
    $vz /= $vmag;
    $ox = sprintf "%.8f",$py*$vz - $pz*$vy;
    $oy = sprintf "%.8f",$pz*$vx - $px*$vz;
    $oz = sprintf "%.8f",$px*$vy - $py*$vx;

    return $ox, $oy, $oz;
}

sub quat_calc {

# calculate Fermi's Z-axis and X-axis vectors in ECI cartesian coordinates    
    my %h = @_;
    $q1 = $h{SG_QBI1};
    $q2 = $h{SG_QBI2};
    $q3 = $h{SG_QBI3};
    $q4 = $h{SG_QBI4};
    $q1sq = $q1**2;
    $q2sq = $q2**2;
    $q3sq = $q3**2;
    $q4sq = $q4**2;
    $qx = 1.0 - $q1sq - $q2sq - $q3sq - $q4sq;
    if (abs($qx) > 1.0e-9) {
	print STDERR "$0: $qx => badly normalized quaternion at time $ymd $hms\n"; 
#	$q4sq = 1.0 - $q1sq - $q2sq - $q3sq;
#	$q4 = sqrt($q4sq);
    }
# calculate the elements of the direction cosine matrix (from Wertz, page 414)

#    $xa = q1sq - q2sq - q3sq + q4sq;
#    $xb = 2*(q1*q2 + q3*q4);
#    $xn = 2*(q1*q3 - q2*q4);
#    $ya = 2*(q1*q2 - q3*q4);
#    $yb = -q1sq + q2sq - q3sq + q4sq;
#    $yn = 2*(q2*q3 + q1*q4);
    $za = sprintf "%.8f",2*($q1*$q3 + $q2*$q4);
    $zb = sprintf "%.8f",2*($q2*$q3 - $q1*$q4);
    $zn = sprintf "%.8f",$q4sq - $q1sq - $q2sq + $q3sq;

    return ($za,$zb,$zn);
}

sub radius {

    my %h = @_;
    $x = $h{SG_NAVPOSJ2000_1}/1000.0;
    $y = $h{SG_NAVPOSJ2000_2}/1000.0;
    $z = $h{SG_NAVPOSJ2000_3}/1000.0;

#    print "$x $y $z\n";
    $rad = sprintf "%.3f",sqrt($x*$x + $y*$y + $z*$z);
    return $rad;
}

sub cullres {

    %hash = ();
    my (@reslines) = @_;
    foreach (@reslines) {
	next unless (/^VAL/);
	@f = split;
	$ymd = $f[1];
	$hms = $f[2];
	($h,$m,$s) = split(':',$hms);
	$hms = sprintf "%02d:%02d:%02d",$h,$m,$s;
	$unixsec = $f[3];
	$unixsec =~ s/\(//;
	$unixsec =~ s/\)//;
	$mnem = $f[4];
	$f[5] =~ s/0+ /0/;
#	$sec = $unixsec if ($mnem =~ m/POS/);
	$hash{$mnem} = $f[5] unless ($hash{$mnem});
#	$hash{$mnem} = $f[5] if (abs($unixsec - $sec) < 0.02);
    }
    $sec = int($unixsec);
    return ($ymd,$hms,$sec,%hash);

}
