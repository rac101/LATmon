#!/usr/local/bin/perl -w

# check times encoded into names of SAA reports against FastCopy received times 

# Robert Cameron
# July 2016

# usage: ./times4reports.pl < SAA.reports

use Time::Local;

while (<>) {
    $line = $_;
    chomp $line;
    s/\// /g;
    ($junk,$p) = split ("fcopy ",$_);
    $p =~ s/\./ /g;
    $p =~ s/utc..//;
    $p =~ s/MOC_//;
# $p now looks like:
# "YYYY MM DOY MM DD DOW  HH MM SS yyyydoyhhmmss L20* vv"
#  2016 06 165 06 13 Mon  12 49 18 2016165084913 L2016165SAA 00
    ($y,$m,$doy,$m,$d,$junk,$uh,$um,$us,$moct,$junk,$junk) = split(' ',$p);
    $unixsecs = timegm($us,$um,$uh,$d,$m-1,$y-1900);
    $ENV{TZ} = 'EST5EDT';
    ($es,$em,$eh,$junk,$junk,$junk,$junk,$junk,$dst) = localtime($unixsecs);
#    $dst = (localtime($unixsecs))[8];
    $dst = ($dst)? "DST" : "non-DST";
    $mocy = substr $moct, 0, 4;
    $mocdoy = substr $moct, 4, 3;
    $moch = substr $moct, 7, 2; 
    $mocm = substr $moct, 9, 2;
    $mocs = substr $moct, -2;
    $et = $eh*3600 + $em*60 + $es;
    $utc = $uh*3600 + $um*60 + $us;
    $moc = $moch*3600 + $mocm*60 + $mocs;
    $d1t = $utc - $moc;
    $d1h = int($d1t/3600);
    $d1m = int(($d1t - $d1h*3600)/60);
    $d1s = sprintf "%02d", $d1t - $d1h*3600 - $d1m*60;
    $d2t = $et - $moc;
    $d2h = int($d2t/3600);
    $d2m = int(($d2t - $d2h*3600)/60);
    $d2s = sprintf "%02d", $d2t - $d2h*3600 - $d2m*60;
    print STDERR "$0: changed Year and/or DOY\n" if ($y != $mocy or $doy != $mocdoy);
    print "$line : $y $doy $d1h:$d1m:$d1s $dst $d2h:$d2m:$d2s\n";
}
