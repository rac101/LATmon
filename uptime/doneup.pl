#!/usr/local/bin/perl -w

# convert floats to a precision of 1 decimal place in the file "tup.out"

# Robert Cameron
# August 2013

#usage
#./doneup.pl < tup.out > tup.done

# to get floats to one decimal place accurately (NOTE: int and sprintf functions do a round down)
# $x = sprintf "%.1f",($x*10

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
#    $s = int($s + 0.5);
    $s = sprintf "%.1f",$s;
    $f[$i] = "$h:$m:$s";
    $i = 3;
    $i++ if (/#/);
    ($h,$m,$s) = split(":",$f[$i]);
#    $s = int($s + 0.5);
    $s = sprintf "%.1f",$s;
    $f[$i] = "$h:$m:$s";
    $i = 4;
    $i++ if (/#/);
    foreach (@f[$i..$#f]) { $_ = sprintf "%.1f",$_ if (/\./) };
    $out = join(' ',@f);
    print "$out\n";
}
