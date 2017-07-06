#!/usr/local/bin/perl -w

# remove excess 0's at the end of floating point numbers
#2009-01-01 14:00:00 1230818400 -6458615.000000000000 1351647.250000000000 2109914.250000000000 -2213.224853515625 -6877.500488281250 -2323.044433593750
#2009-01-01 14:00:00 1230818400 -6458615.0 1351647.250 2109914.250 -2213.225 -6877.500 -2323.044

# Robert Cameron
# September 2013

# usage: ./trunc0.pl nav.YYYY > nav.YYYY-fixed

while (<>) {
    @f = split;
    $f[3] .= ' ';
    $f[3] =~ s/0+ /0/;
    $f[4] .= ' ';
    $f[4] =~ s/0+ /0/;
    $f[5] .= ' ';
    $f[5] =~ s/0+ /0/;
    $f[6] = sprintf "%.4f", $f[6];
    $f[7] = sprintf "%.4f", $f[7];
    $f[8] = sprintf "%.4f", $f[8];
    $out = join (' ',@f);
    print "$out\n";
}
