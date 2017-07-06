#!/usr/local/bin/perl -w

# calculate memory error rates, reading memory error file from STDIN

#Usage: > ./rate.pl < geosaa.out

#EPU1: 2012-04-22 18:21:41.784301 (1335118901.784301)  Address:   62151696 (0x03b45c10)  Type: 4 (Correctable multi-bit error) -25.944944 -23.729332 1
#EPU0: 2012-04-22 18:21:50.934978 (1335118910.934978)  Address:   99947224 (0x05f512d8)  Type: 3 (Correctable single-bit error) -25.376673 -23.628370 1
# SIU: 2012-04-22 20:02:09.423836 (1335124929.423836)  Address:  131599768 (0x07d80d98)  Type: 4 (Correctable multi-bit error) -31.731960 -19.124795 1
#EPU1: 2012-04-22 21:46:49.660921 (1335131209.660921)  Address:   94636400 (0x05a40970)  Type: 3 (Correctable single-bit error) -25.210983 -6.104414 1

while (<>) {
    chomp;
    next unless (/Address/);
    s/\(//g;
    s/\)//g;
    @f = split;
    $t = $f[3];
    $t6 = int($t/1.0e6 - 0.7);
    $t7 = int($t/1.0e7 - 0.77);
    $r6{$t6}++;
    $r7{$t7}++;
    $rs6{$t6}++ if (/single/);
    $rs7{$t7}++ if (/single/);
    $rm6{$t6}++ if (/multi/);
    $rm7{$t7}++ if (/multi/);
}

@k6 = sort (keys %r6);
@k7 = sort (keys %r7);

print "Memory error counts per 1 million seconds:\n";
print "Unix sec/1e6-0.7 Single\tMulti\tTotal\n";
foreach (@k6) { 
    $m = ($rm6{$_})? $rm6{$_} : 0;
    print "\t$_\t$rs6{$_}\t$m\t$r6{$_}\n";
}
print "\n";
print "Memory error counts per 10 million seconds:\n";
print "Unix sec/1e7-0.77 Single\tMulti\tTotal\n";
foreach (@k7) { 
    $m = ($rm7{$_})? $rm7{$_} : 0;
    print "\t$_\t$rs7{$_}\t$m\t$r7{$_}\n";
}
