#!/usr/local/bin/perl -w

# split a LATC/LCFG dump text file into separate dump files

# example info from grep for starts of Dumps
#1:LAT Registers             2018-09-30 01:49:45
#149293:LAT Registers             2018-09-30 01:50:10
#298585:LAT Registers             2018-09-30 03:07:01
#447701:LAT Registers             2018-09-30 03:28:53
#596817:LAT Registers             2018-09-30 03:29:18

# Robert Cameron
# April 2019

die "$0: Need an input text dump filename as argument!\n" unless ($ARGV[0] and -e $ARGV[0]);

$finp = $ARGV[0];
$wcl = `wc -l $finp`;
@f = split(' ',$wcl);
$flen = $f[0];

@dumps = `grep -n Registers $finp`;
print STDERR @dumps;

die "$0: No starts of dumps found, so no output\n" unless (@dumps);
$ndumps = scalar(@dumps);
die "$0: Only 1 dump start found, so no output\n" unless (scalar(@dumps) gt 1);
print STDERR "$0: $ndumps separate dumps found in $finp\n";
 
@dbeg = ();
@dtime = ();

foreach (@dumps) {
    @f = split;
    @g = split(':',$f[0]);
    push @dbeg,$g[0];
    push @dtime,$f[-1];
}
print STDERR "$0: WARNING! First dump start found at line $dbeg[0]\n" if ($dbeg[0] > 1);

#push @dbeg,$flen;
foreach $f (1..$#dbeg) {
    $headlen = $dbeg[$f]-1;
    $dlen = $headlen - $dbeg[$f-1]; 
    $fout = "lcfg$f.$dtime[$f-1]";
    print STDERR "$0: Extracting dump $f of $dlen lines, from input line $dbeg[$f-1] to input line $headlen\n";
    $cmd ="head -$headlen $finp | tail -$dlen > $fout"; 
#    print STDERR "$0: About to run the command: $cmd\n";
    `$cmd`;
#    print STDERR "$0: Just ran the command: $cmd\n";
}

# output final dump file
$f = $ndumps;
$fout = "lcfg$f.$dtime[-1]";
$dlen = $flen - $dbeg[-1];
print STDERR "$0: Extracting dump $f of $dlen lines, from input line $dbeg[-1] to input line $flen\n";
`tail -$dlen $finp > $fout`;

