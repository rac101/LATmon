#!/usr/local/bin/perl -w

# check timesteps between lines of the LAT VCHP heater history files
# 
# example lines:
#2008-06-26 00 7513 513 06 7513 507 07 7513 945 01 7513 272 08 7513 39
#2008-06-27 00 7513 399 06 7513 321 07 7513 851 01 7513 57
#2008-06-28 00 7513 409 06 7513 368 07 7513 767 01 7513 47
#2008-06-29 00 7513 414 06 7513 349 07 7513 691
#
# should be 1 day between lines

# Robert Cameron
# October 2013

# usage: ./xhtr.pl < htr.history

# MET (seconds) at the start of the Fermi mission (2008 June 11, 16:05 UTC)
$t0 = 1213200301;
$numdays = 20*365;
foreach $i (0..$numdays) { 
    ($dum,$dum,$dum,$day,$mon,$year,$dum,$dum,$dum) = gmtime($t0);
    $date = sprintf "%d-%02d-%02d",$year+1900,$mon+1,$day;
    $dhash{$date} = $i;
    $t0 += 86400;
}

$iold = 0;
$dold = 'NO DATE';
$linecount = 0;
while (<>) {
    $linecount++;
    @f = split;
    $nf = scalar(@f);
    if ($nf < 10) { print "$0: at line $linecount, $f[0], only $nf parameters on the line\n" };
    if ($f[2] == 0 or $f[5] == 0 or $f[8] == 0) { print "$0: at line $linecount, $f[0], one or more sample counts is 0\n" }; 
    if ($f[2] < 7300 or $f[5] < 7300 or $f[8] < 7300) { print "$0: at line $linecount, $f[0], one or more sample counts is <7300\n" }; 
    $i = $dhash{$f[0]};
    if ($i != $iold+1 and $linecount > 1) { print "$0: at line $linecount, invalid time step from $dold to $f[0]\n" }
    $dold = $f[0];
    $iold = $i;
}
