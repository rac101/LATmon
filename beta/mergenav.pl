#!/usr/local/bin/perl -w

# merge multiple input nav files into a single output file
# also remove duplicate lines and 
# warn if non-matching lines for the same time stamp are found

# Robert Cameron
# February 2014

# usage: ./mergenav.pl nav.file1 nav.file2 [...nav.fileN] > nav.merged

# example input record
# 2013-11-20 03:00:00 1384916400 -3792871.750 4992694.0 -2929016.0 -5846.0435 -4806.1543 -599.7345

@infiles = @ARGV;
print STDERR "$0: ",scalar(@infiles)," input files will be checked\n";

foreach $if (@infiles) {
    print STDERR "$0: opening input file: $if\n";
    open(IF, $if) or die "$0: Could not open input file: $if\n";
    while (<IF>) {
	@f = split;
	next unless (@f == 9);
	$key = "$f[0] $f[1]";
	if ($h{$_}) { print STDERR "$0: found duplicated line: $_"; next };
	if ($kh{$key}) { print STDERR "$0: found duplicated time with different data:\n$_ $kh{$key}"; next };
	$h{$_} = 1;
	$kh{$key} = $_;
    }
}

# output sorted records to STDOUT

@ok = sort (keys %kh);
foreach (@ok) { print $kh{$_} };
