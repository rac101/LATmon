#!/usr/local/bin/perl -w

# for Memory errors from MnemRet.py, first pretty print, then append GEOLAT and GEOLON and SAA in/out flag
# here is the format of the MnemRet.py command:
# MnemRet.py --beg '-1 days' --end '2012-04-23 00:00:00' LCMMEMCPUNODE 
# LCMMEMLOG0TYP LCMMEMLOG0ADD LCMMEMLOG1TYP LCMMEMLOG1ADD LCMMEMLOG2TYP LCMMEMLOG2ADD LCMMEMLOG3TYP LCMMEMLOG3ADD
# 
# here is the format of the output from the MnemRet.py command:
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMCPUNODE                             0 (                         0)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG0TYP                  2735211544.0 (                2735211544)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG0ADD                      21896792 (                  21896792)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG1TYP                     588022416 (                 588022416)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG1ADD                      74106832 (                  74106832)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG2TYP                     588022416 (                 588022416)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG2ADD                      74106832 (                  74106832)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG3TYP                     588022416 (                 588022416)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG3ADD                      74106832 (                  74106832)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMCPUNODE                             1 (                         1)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG0TYP                  2735483968.0 (                2735483968)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG0ADD                      84023688 (                  84023688)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG1TYP                     587794504 (                 587794504)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG1ADD                      55618400 (                  55618400)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG2TYP                     587794504 (                 587794504)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG2ADD                      55618400 (                  55618400)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG3TYP                     587794504 (                 587794504)
#VAL: 2012-08-03 08:55:52.609572 (1343984152.609572) LCMMEMLOG3ADD                      55618400 (                  55618400)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMCPUNODE                             0 (                         0)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG0TYP                  2752433248.0 (                2752433248)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG0ADD                     106307352 (                 106307352)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG1TYP                     588128784 (                 588128784)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG1ADD                      42791424 (                  42791424)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG2TYP                     588128784 (                 588128784)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG2ADD                      42791424 (                  42791424)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG3TYP                     588128784 (                 588128784)
#VAL: 2012-08-03 09:01:11.407469 (1343984471.407469) LCMMEMLOG3ADD                      42791424 (                  42791424)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMCPUNODE                             2 (                         2)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG0TYP                  2735342658.0 (                2735342658)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG0ADD                      47656656 (                  47656656)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG1TYP                     588251138 (                 588251138)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG1ADD                      64914976 (                  64914976)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG2TYP                     588251138 (                 588251138)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG2ADD                      64914976 (                  64914976)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG3TYP                     588251138 (                 588251138)
#VAL: 2012-08-03 10:35:43.856702 (1343990143.856702) LCMMEMLOG3ADD                      64914976 (                  64914976)
#
#and here is the output from make_pretty.py:
# SIU: 2012-08-03 06:10:50.943643 (1343974250.943643)  Address:   21896792 (0x014e1e58)  Type: 3 (Correctable single-bit error)
#EPU0: 2012-08-03 08:55:52.609572 (1343984152.609572)  Address:   84023688 (0x05021988)  Type: 3 (Correctable single-bit error)
# SIU: 2012-08-03 09:01:11.407469 (1343984471.407469)  Address:  106307352 (0x06561f18)  Type: 4 (Correctable multi-bit error)
#EPU1: 2012-08-03 10:35:43.856702 (1343990143.856702)  Address:   47656656 (0x02d72ed0)  Type: 3 (Correctable single-bit error)

# Robert Cameron
# August 2012

# usage: ./geosaa.pl >> geosaa.out

$wdir = "/nfs/farm/g/glast/u55/rac/LATmetrics/memerr";
$mnems = "LCMMEMCPUNODE LCMMEMLOG0TYP LCMMEMLOG0ADD LCMMEMLOG1TYP LCMMEMLOG1ADD LCMMEMLOG2TYP LCMMEMLOG2ADD LCMMEMLOG3TYP LCMMEMLOG3ADD";
 
#`source /u/gl/glastops/flightops.sh`;
$cmd = 'date --date="-12 days" +"%F 00:00:00"';
$day = `$cmd`;
chop $day;
#print STDERR "$0: Working on day $day\n";
#$cmd = "PktDump.py --apid 718 -b '-1 days' -e '$day'";
$cmd = "MnemRet.py -b '-2 days' -e 'now' $mnems | $wdir/make_pretty.py";
#$cmd = "MnemRet.py -b '2012-08-11 10:00:00' -e '+2 day' $mnems | $wdir/make_pretty.py";
#print STDERR "$0: About to execute the command: $cmd<<<<<<\n";
@merr = `$cmd`;
#print STDERR "$0: the following memory errors were found:\n",@merr;

foreach (@merr) { 
    chomp;
    $err = $_;
    @fld = split;
    $cmd = "MnemRet.py -b '-1 seconds' -e '$fld[1] $fld[2]' SGPSBA_LONGITUDE SGPSBA_LATITUDE SACFLAGLATINSAA";
#    print STDERR "$0: About to execute the command: $cmd<<<<<<\n";
    @loc = `$cmd`;
#    print STDERR "$0: The MnemRet.py result is: \n",@loc;
    print $err;
    foreach (keys(%hash)) { $hash{$_} = -9999 };
    if ($loc[4] =~ "VAL" || $loc[5] =~ "VAL" || $loc[6] =~ "VAL") {
	foreach (@loc) {
	    next unless /VAL/;
	    @val = split;
	    $hash{$val[4]} = $val[5];
	}
    }
    print " $hash{SGPSBA_LONGITUDE} $hash{SGPSBA_LATITUDE} $hash{SACFLAGLATINSAA}\n";
}
print "\n";
