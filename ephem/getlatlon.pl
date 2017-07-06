#!/usr/local/bin/perl -w

# get hourly Fermi latitude and longitude telemetry
# here is the format of the MnemRet.py command:
# MnemRet.py -b '2017-05-18 10:00:00' -e '+1 hour' SGPSBA_LATITUDE SGPSBA_LONGITUDE
#
# which produces the output:
#VAL: 2017-05-18 10:00:00.940077 (1495101600.940077) SGPSBA_LATITUDE                  -10.542646 (                 -37953521)
#VAL: 2017-05-18 10:00:00.940077 (1495101600.940077) SGPSBA_LONGITUDE                 157.301150 (                 566284093)
#VAL: 2017-05-18 10:00:01.940076 (1495101601.940076) SGPSBA_LATITUDE                  -10.517345 (                 -37862438)
#VAL: 2017-05-18 10:00:01.940076 (1495101601.940076) SGPSBA_LONGITUDE                 157.355839 (                 566480974)

# output to STDOUT will be
# YYYY MM DD DOY HH MM SS.ssssss unix-time MET lat long

# Robert Cameron
# May 2017

# usage: ./getlatlon.pl < mnemret.YYYYMMDD > latlon.YYYYMMDD

# DOY offsets per calendar month, for leap and non-leap years

@doym = ([0, 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335], 
         [0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334], 
         [0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334], 
         [0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]);

$ymd2 = 0;
$hms2 = 0;
$par1 = 0;
$par2 = 0;
# read in the data 2 lines at a time
while ($pair = <>.<>) {
    $_ = $pair;
    next unless (/VAL/);
#    print $_;
    s/\n/ /;
    die "$0: input read is out of VAR sync at $_" unless (/.+LAT.+LONG/);
    s/(\(|\))//g;
    ($junk,$ymd1,$hms1,$utc1,$par1,$val1,$junk,$junk,$ymd2,$hms2,$utc2,$par2,$val2,$junk) = split;
    die "$0: input read is out of TIME sync at $_" unless ($utc1 == $utc2);
    $ymd1 =~ s/-/ /g;
    ($y, $m, $d) = split(' ',$ymd1);
    $doy = sprintf "%03i", $doym[$y % 4][$m] + $d;
    $hms1 =~ s/:/ /g;
    $met = $utc1 - 978307200;
    print "$ymd1 $doy $hms1 $utc1 $met $val1 $val2\n";
}
