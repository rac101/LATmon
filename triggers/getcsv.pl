#!/usr/local/bin/perl -w

# usage: 
# ( ./getcsv.pl < 2008files > callrs.dat ) >& lrsERR.dat

while (<>) {
    open FF, $_;
    print STDERR "reading file $_";
    while (<FF>) {
	s/,/ /g;
	@F = split; 
	if ($F[0] > 23e7 && $F[0] < 26e7) { $t = $F[0] };
	if ($F[0] <= 15) { $t .= " $F[1] $F[2]" };
	if ($F[0] == 15) { print "$t\n" };
    }
}
