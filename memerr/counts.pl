#!/usr/local/bin/perl -w

# count memory error types, reading memory error file from STDIN

#Usage: > ./counts.pl < geosaa.out

#EPU1: 2012-04-22 18:21:41.784301 (1335118901.784301)  Address:   62151696 (0x03b45c10)  Type: 4 (Correctable multi-bit error) -25.944944 -23.729332 1
#EPU0: 2012-04-22 18:21:50.934978 (1335118910.934978)  Address:   99947224 (0x05f512d8)  Type: 3 (Correctable single-bit error) -25.376673 -23.628370 1
# SIU: 2012-04-22 20:02:09.423836 (1335124929.423836)  Address:  131599768 (0x07d80d98)  Type: 4 (Correctable multi-bit error) -31.731960 -19.124795 1
#EPU1: 2012-04-22 21:46:49.660921 (1335131209.660921)  Address:   94636400 (0x05a40970)  Type: 3 (Correctable single-bit error) -25.210983 -6.104414 1

$b = 0;
while (<>) {
    chomp;
    unless ($_) {$b++; next};
    @f = split;
    $t{"$f[0] $f[9] $f[10] error)"}++;
}

$c = 0;
$cepu0 = 0;
$cepu1 = 0;
$csiu = 0;
@skeys = ("SIU: (Correctable single-bit error)","EPU0: (Correctable single-bit error)","EPU1: (Correctable single-bit error)");
@mkeys = ("SIU: (Correctable multi-bit error)","EPU0: (Correctable multi-bit error)","EPU1: (Correctable multi-bit error)");
print "\t\tSIU\tEPU0\tEPU1";
print "\nsingle-bit ";
foreach (@skeys) {
    print "\t$t{$_}"; 
    $c += $t{$_};
    if ($_ =~ 'EPU0') { $cepu0 += $t{$_} };
    if ($_ =~ 'EPU1') { $cepu1 += $t{$_} };
    if ($_ =~ 'SIU') { $csiu += $t{$_} };
} 
print "\nmulti-bit ";
foreach (@mkeys) {
    print "\t$t{$_}"; 
    $c += $t{$_};
    if ($_ =~ 'EPU0') { $cepu0 += $t{$_} };
    if ($_ =~ 'EPU1') { $cepu1 += $t{$_} };
    if ($_ =~ 'SIU') { $csiu += $t{$_} };
} 
print "\nTotal\t\t$csiu\t$cepu0\t$cepu1\n";
print "\nTotal number of errors = $c\n";
print "with $b blank lines\n";
