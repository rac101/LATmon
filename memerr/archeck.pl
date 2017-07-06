#!/usr/local/bin/perl -w

# report on missing days in the LAT memory error archive file

#Usage: > ./archeck.pl < geosaa.out

#input format
#EPU1: 2012-04-22 18:21:41.784301 (1335118901.784301)  Address:   62151696 (0x03b45c10)  Type: 4 (Correctable multi-bit error) -25.944944 -23.729332 1
#EPU0: 2012-04-22 18:21:50.934978 (1335118910.934978)  Address:   99947224 (0x05f512d8)  Type: 3 (Correctable single-bit error) -25.376673 -23.628370 1
# SIU: 2012-04-22 20:02:09.423836 (1335124929.423836)  Address:  131599768 (0x07d80d98)  Type: 4 (Correctable multi-bit error) -31.731960 -19.124795 1
#EPU1: 2012-04-22 21:46:49.660921 (1335131209.660921)  Address:   94636400 (0x05a40970)  Type: 3 (Correctable single-bit error) -25.210983 -6.104414 1

@doy = ([0,0,31,59,90,120,151,181,212,243,273,304,334],[0,0,31,60,91,121,152,182,213,244,274,305,335]);
@dom = (-163);   # linear Day Of Mission for Fermi for start of each year, starting with 2008. Mission start date = 11 June 2008 = doy 163.
foreach (1..99) {
    $n = 365;
    if (($_ % 4) == 1) { $n = 366 };
    push @dom,$dom[$_-1]+$n;
}

$pmd = 0;
while (<>) {
    next unless (/U/);
    @f = split; 
    ($y,$m,$d) = split('-',$f[1]);
    $leap = 0;
    $leap = 1 unless ($y % 4);
    $md = $dom[$y - 2008] + $doy[$leap][$m] + $d; 
    next if ($md == $pmd);
    if ($md != $pmd+1) { $dd = $md - $pmd; print "Found $dd day jump in archive file to: $f[1] $f[2] = mission day $md\n" };
    $pmd = $md;
}
