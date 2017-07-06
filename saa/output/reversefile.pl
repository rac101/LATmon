#!/usr/local/bin/perl -w

# reverse the output order of the file "saax.txt"

# Robert Cameron
# February 2015

# usage: ./reversefile.pl
# read from STDIN
# write to STDOUT

@f = (<>);
@r = reverse @f;
foreach (@r) { if (/\d/) { push @rec, $_ } else { @b = reverse @rec; print "@b\n"; @rec = () } };
