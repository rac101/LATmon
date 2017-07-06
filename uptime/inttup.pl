#!/usr/local/bin/perl -w

# convert floats to integers in the file "tup.out"

# Robert Cameron
# August 2013

#usage
#./inttup.pl < tup.out > tup.int

print "                                                ";
print "|LIM   Cal Dia PiS TO TiS AiS HldBtOf|SAA--|-----LPA-------|--LCI-----|\n";
print "t0                    t1                  ";
print "Total Term Qui C D Phy   P T T ARR A H B O SAA   Idle  Run Stop ? Idle  R S ?\n";
while (<>) {
    next unless (/20/);
    @f = split;
    $i = 1;
    $i++ if (/#/);
    ($h,$m,$s) = split(":",$f[$i]);
    $s = int($s + 0.5);
    $s = sprintf "%02d",$s;
    $f[$i] = "$h:$m:$s";
    $i = 3;
    $i++ if (/#/);
    ($h,$m,$s) = split(":",$f[$i]);
    $s = int($s + 0.5);
    $s = sprintf "%02d",$s;
    $f[$i] = "$h:$m:$s";
    $i = 4;
    $i++ if (/#/);
    foreach (@f[$i..$#f]) { $_ = int($_ + 0.5) };
    $out = join(' ',@f);
    print "$out\n";
}
