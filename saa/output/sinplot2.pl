#!/usr/local/bin/perl -w

# reformat SAA timing report file into a format suitable for plotting in IDL

# Robert Cameron
# February 2017

# usage: ./sinplot2.pl
# read from STDIN
# write to STDOUT

@ylen = (366.0,365.0,365.0,365.0);

# example input line:
#L2014300SAA.03, 588 lines, wrt L2014293SAA.00: 518 matched SAAs: min, max, avg dT = 0.248, 46.668, 10.915
while (<>) {
    next if (/exceeds/);
    chomp;
    s/,//g;
    @f = split;
    foreach $w (@f) {
	$rep = $w;
	last if ($w =~ /L20/);
    }
    $t1 = $f[-3];
    $t2 = $f[-2];
    $t3 = $f[-1];
    next if ($t1 == 0.0 and $t2 == 0.0 and $t3 == 0.0);
    ($st1,$st2,$st3) = sort { $a <=> $b } ($t1,$t2,$t3);
    $rep =~ /L(\d\d\d\d)(\d\d\d)SAA/;
    $y = $1; 
    $d = $2;
    $leap = $y % 4;
    $fy = sprintf "%.3f",$y + $d/$ylen[$leap];
#    print "$y $d $fy $rep $st1 $st2 $st3\n";
    print "$fy $st1 $st2 $st3\n";
}
