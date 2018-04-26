#!/usr/bin/perl -w

#  inspect a "sum.NN" file read from STDIN and show lines with > 100 bad strips

# Robert Cameron
# 2018 April
 
# example line from a sum.NN file:
# TKR: 0 Layer: X1 = 2 Scount = 187

while (<>) {
    next unless (/Scount/);
    @f = split;
    print $_ if ($f[-1] > 100);
}
