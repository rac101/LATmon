#!/usr/local/bin/perl -w

# maintain an up-to-date list of SAA reports

# Robert Cameron
# January 2016

# usage: ./filistSAA.pl
# will run silently if no new SAA report files are found

use File::Basename;
$sn = basename($0);

# read in the existing list of SAA reports, from the file "SAA.reports"
$wdir = "/u/gl/rac/LATmetrics/saa";
@xr = `cat $wdir/SAA.reports`;
foreach (@xr) { chomp; $xrep{$_} = 1 };
#print "$sn: latest SAA report is $xr[-1]\n";

# path to the FastCopy archive of SAA reports 
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# get recent days' Year/Month/DOY
$day0 = `date +"%Y/%m/%j.*"`;
$day1 = `date --date="yesterday" +"%Y/%m/%j.*"`;
chomp $day0;
chomp $day1;

# look for recent SAA reports in the FastCopy archive
@r0 = `find $fcdir/$day0 -name 'L20*SAA*'`;
@r1 = `find $fcdir/$day1 -name 'L20*SAA*'`;
exit unless (@r0 or @r1);
@r = sort (@r1,@r0);

# append the names of new SAA reports, in order, into "SAA.reports".
foreach (@r) { 
    chomp;
#    print "$sn: found: $_\n";
    next if ($xrep{$_});
    next unless (/SAA/);
    $file = $_;
    $file =~ s/($fcdir)//;
    print "$sn: adding new SAA report to 'SAA.reports':\n\t$file\n";
    `echo "$_" >> $wdir/SAA.reports`;
}

# finally, refresh the list on the ops webpage

$odir = '/afs/slac/www/exp/glast/ops';
`rm $odir/SAAreports.txt`;
`tac $wdir/SAA.reports > $odir/SAAreports.txt`;
