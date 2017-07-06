#!/usr/local/bin/perl -w

# remove repeat lines in the nav files

# Robert Cameron
# September 2013

# usage: ./delrep.pl nav.YYYY > nav.YYYY-fixed

%h = ();
while (<>) {
    if ($h{$_}) {
	print STDERR "$0: found duplicated line: $_"; next };
    print $_;
    $h{$_} = 1;
}
