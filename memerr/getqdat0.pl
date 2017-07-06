#!/usr/local/bin/perl -w

# extract memory errors from the archive file, for plotting
# do the extraction by year and calendar quarter

# typically STDOUT goes to "idl.inp", which is then transferred to the Mac for plotting in IDL

#Usage: > ./getqdat.pl Year Quarter > STDOUT
#e.g.   > ./getqdat.pl 2012 4 > idl-2012-q4.inp

#input format
#EPU1: 2012-04-22 18:21:41.784301 (1335118901.784301)  Address:   62151696 (0x03b45c10)  Type: 4 (Correctable multi-bit error) -25.944944 -23.729332 1
#EPU0: 2012-04-22 18:21:50.934978 (1335118910.934978)  Address:   99947224 (0x05f512d8)  Type: 3 (Correctable single-bit error) -25.376673 -23.628370 1
# SIU: 2012-04-22 20:02:09.423836 (1335124929.423836)  Address:  131599768 (0x07d80d98)  Type: 4 (Correctable multi-bit error) -31.731960 -19.124795 1
#EPU1: 2012-04-22 21:46:49.660921 (1335131209.660921)  Address:   94636400 (0x05a40970)  Type: 3 (Correctable single-bit error) -25.210983 -6.104414 1

#output format
#2012 01 01 01 06 56.154309 1325380016.154309 -44.541621 -18.590303 1
#2012 01 01 01 16 42.527233 1325380602.527233 -7.914734 -25.558265 1
#2012 01 01 02 41 39.607996 1325385699.607996 -71.377023 -17.748865 1
#2012 01 01 02 42 00.550470 1325385720.550470 -70.153971 -18.171452 1

($year,$qtr) = @ARGV;
die "$0: $year is a bad year\n" unless ($year >= 2012 and $year <= 2020);
die "$0: $qtr is a bad quarter\n" unless ($qtr >= 1 and $qtr <= 4);

%qhash = ('01',1,'02',1,'03',1,'04',2,'05',2,'06',2,'07',3,'08',3,'09',3,'10',4,'11',4,'12',4);

open (AF,'geosaa.out') or die "$0: Cannot open archive data file\n";
while (<AF>) {
    next unless (/ $year-/);
    s/\(//;
    s/\)//;
    @f = split;
    ($y,$month,$d) = split('-',$f[1]);
    next unless ($qhash{$month} == $qtr);
    ($h,$m,$s) = split(':',$f[2]);
    print "$y $month $d $h $m $s $f[3] $f[12] $f[13] $f[14]\n";
}
