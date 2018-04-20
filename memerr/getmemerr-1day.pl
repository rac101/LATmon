#!/usr/local/bin/perl -w

# get LAT memory errors for a specified date

# find Memory errors from MnemRet.py, then first pretty print, then append GEOLAT and GEOLON and SAA in/out flag
# here is the format of the MnemRet.py command:
# MnemRet.py --beg '-1 days' --end '2012-04-23 00:00:00' LCMMEMCPUNODE 
# LCMMEMLOG0TYP LCMMEMLOG0ADD LCMMEMLOG1TYP LCMMEMLOG1ADD LCMMEMLOG2TYP LCMMEMLOG2ADD LCMMEMLOG3TYP LCMMEMLOG3ADD
# 
# here is the format of the output from the MnemRet.py command:
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMCPUNODE             0 (           0)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG0TYP  2735211544.0 (  2735211544)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG0ADD      21896792 (    21896792)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG1TYP     588022416 (   588022416)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG1ADD      74106832 (    74106832)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG2TYP     588022416 (   588022416)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG2ADD      74106832 (    74106832)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG3TYP     588022416 (   588022416)
#VAL: 2012-08-03 06:10:50.943643 (1343974250.943643) LCMMEMLOG3ADD      74106832 (    74106832)
#
#and here is the output from make_pretty.py:
# SIU: 2012-08-03 06:10:50.943643 (1343974250.943643)  Address:   21896792 (0x014e1e58)  Type: 3 (Correctable single-bit error)
#EPU0: 2012-08-03 08:55:52.609572 (1343984152.609572)  Address:   84023688 (0x05021988)  Type: 3 (Correctable single-bit error)
# SIU: 2012-08-03 09:01:11.407469 (1343984471.407469)  Address:  106307352 (0x06561f18)  Type: 4 (Correctable multi-bit error)
#EPU1: 2012-08-03 10:35:43.856702 (1343990143.856702)  Address:   47656656 (0x02d72ed0)  Type: 3 (Correctable single-bit error)

# Robert Cameron
# April 2018

# usage: ./getmemerr-1day.pl YYYY-mm-dd >> memerr.history

use Try::Tiny;

use strict 'subs';
use strict 'refs';

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 600;
    main();
    alarm 10;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: Try timed out\n";
}
finally {
#    print "done\n";
};

#####################################
sub main {

    $mnems = "LCMMEMCPUNODE LCMMEMLOG0TYP LCMMEMLOG0ADD LCMMEMLOG1TYP LCMMEMLOG1ADD LCMMEMLOG2TYP LCMMEMLOG2ADD LCMMEMLOG3TYP LCMMEMLOG3ADD";

    $wdir = "/u/gl/rac/LATmetrics/memerr";

# first get the required date as the input argument

    $startdate = $ARGV[0];

    $cmd = "MnemRet.py -b '$startdate 00:00:00' -e '+1 day' $mnems | $wdir/make_pretty.py";
    @merr = `$cmd`;

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
    }  # end of memory errors loop
    print "\n";
}  # end of main sub 
