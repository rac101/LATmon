#!/usr/local/bin/perl -w

# maintain an up-to-date list of GLAST ephemeris files

# Robert Cameron
# January 2016

# usage: ./filistEphem.pl
# will run silently if no new GLAST ephemeris files are found

use File::Basename;
$sn = basename($0);

# read in the existing list of ephemeris files, from the file "EPHEM.files"
$wdir = "/u/gl/rac/LATmetrics/planning";
@xr = `cat $wdir/EPHEM.files`;
foreach (@xr) { chomp; $xrep{$_} = 1 };
#print "$sn: latest ephemeris file is $xr[0]\n";

# path to the FastCopy archive of ephemeris files 
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# get recent days' Year/Month/DOY
$day0 = `date +"%Y/%m/%j.*"`;
$day1 = `date --date="yesterday" +"%Y/%m/%j.*"`;
chomp $day0;
chomp $day1;

# look for recent GLAST ephemerides reports in the FastCopy archive
@r0 = `find $fcdir/$day0 -name 'GLAST_EPH_20*'`;
@r1 = `find $fcdir/$day1 -name 'GLAST_EPH_20*'`;
exit unless (@r0 or @r1);
@r = sort (@r1,@r0);

# append the names of new ephemeris files, in order, into "EPHEM.files".
foreach (@r) { 
    chomp;
    next if ($xrep{$_});
    next unless (/GLAST_EPH_20/);
    $file = $_;
    $file =~ s/($fcdir)\//($fcdir)\/\n  /;
    $file =~ s/\/GLAST_EPH_20/\/\n  GLAST_EPH_20/;
    print "$sn: adding new ephemeris file to 'EPHEM.files':\n\t$file\n";
    `echo "$_" >> $wdir/EPHEM.files`;
}

# finally, refresh the list (newest file first) on the ops webpage

$odir = '/afs/slac/www/exp/glast/ops';
`rm $odir/EPHEMfiles.txt`;
`tac $wdir/EPHEM.files > $odir/EPHEMfiles.txt`;
