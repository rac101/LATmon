#!/usr/local/bin/perl -w

# check SAA reports
# 1. check if SAA entries can have the same orbit number.
# 2. check if SAA exits can have the same orbit number.

# Robert Cameron
# January 2015

# usage: ./csaax.pl

$wdir = "/u/gl/rac/LATmetrics/saa/reports";
@rep = `ls -1 $wdir`;

# typical lines from an SAA report:
#365/2014 20:46:21.642,"36134",365/2014 20:56:22.845,"36134",10.020
#001/2015 05:37:10.333,"36140",001/2015 05:44:57.363,"36140",7.784

foreach $r (@rep) {
    chomp $r;
    @lines = `cat $wdir/$r`;
    $nl = @lines;
    print "$0: $nl lines in $r\n";
    %orbin = ();
#    %orbout = ();
    foreach (@lines) {
	next unless (/20/);
	s/,/ /g;
	@f = split('"',$_);
	$in = $f[1];
#	$out = $f[3];
	if ($orbin{$in}) { print "$0: input orbit repeated at $_" };
	$orbin{$in} = 1;
#	if ($orbout{$out}) { print "$0: output orbit repeated at $_" };
#	$orbout{$out} = 1;
    }
}
