#!/usr/bin/perl -w

#  inspect a "sum.NN" file read from STDIN and show lines with > 100 bad strips

# Robert Cameron
# 2015 April
 
# example line from a sum.NN file:
#       TKR: 0  Tray:7  SIDE: top       Layer: X7 = 14  Scount = 105    Slist: HASH     Sspan: HASH

while (<>) {
    next unless (/Scount/);
    @f = split;
    print $_ if ($f[11] > 100);
}
