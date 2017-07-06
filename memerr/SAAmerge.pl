#!/usr/local/bin/perl -w

# add geographic coordinates and SAA flag to each memory error, for those lines that are missing these data

#Usage: > ./SAAmerge.pl file-of-augmented-records geosaa.out > improved-geosaa.out

# Robert Cameron
# August 2015

# read in the file of new records, into a hash, keyed by all the record before the geo+SAA values
# then process the file "geosaa.out", replacing incomplete or deficient records with matching new records from the hash.
 
#input format
#EPU1: 2012-04-22 18:21:41.784301 (1335118901.784301)  Address:   62151696 (0x03b45c10)  Type: 4 (Correctable multi-bit error) -25.944944 -23.729332 1
#EPU0: 2012-04-22 18:21:50.934978 (1335118910.934978)  Address:   99947224 (0x05f512d8)  Type: 3 (Correctable single-bit error) -25.376673 -23.628370 1
# SIU: 2012-04-22 20:02:09.423836 (1335124929.423836)  Address:  131599768 (0x07d80d98)  Type: 4 (Correctable multi-bit error) -31.731960 -19.124795 1
#EPU1: 2012-04-22 21:46:49.660921 (1335131209.660921)  Address:   94636400 (0x05a40970)  Type: 3 (Correctable single-bit error) -25.210983 -6.104414 1

($newrecfile, $oldrecfile)  = @ARGV;

open my $newf, '<', $newrecfile or die $!; 

$hash = {};
$newrec = 0;

while (<$newf>) { 
    next unless (/U/);
    $newrec++;
    $line = $_;
    s/error.*/error\)/;
    $hash{$_} = $line;
}
close $newf;
print STDERR "$0: $newrec new records read into hash from $newrecfile\n";

open my $oldf, '<', $oldrecfile or die $!;

$oldline = 0;
$repline = 0;

while (<$oldf>) {
    $oldline++;
    s/ -9999 -9999 -9999//;
    if ($hash{$_}) { print $hash{$_}; $repline++ } else { print $_ };
}
print STDERR "$0: $oldline lines read from $oldrecfile; and $repline lines replaced\n";
close $oldf;
