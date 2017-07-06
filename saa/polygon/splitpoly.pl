#!/usr/local/bin/perl -w

# split the file history.ppoly into separate outputs for SAA1 and SAA2

# input from STDIN

# output to STDOUT

# Robert Cameron
# May 2017

# usage: ./splitpoly.pl < history.poly > history[12].poly

# read in the history one line at a time

while (<>) {
    chomp;
    ($t1,$t2,$t3,@val) = split;
#    @tval = @val[0..23];
    @tval = @val[24..$#val];
    $out = join " ",($t1,$t2,$t3,@tval);
    print "$out\n";
}
