#!/usr/local/bin/perl -w

# XML inspection script, to recover CAL photodiode gains
# Robert Cameron
# 2015 July
# 
# call this script with the XML filename as the first command argument

# example lines of interest in the XML file:
#<mevPerDac smallSig="1.742690" bigVal="0.401917" smallVal="21.741199" bigSig="0.032216">
#<mevPerDac smallSig="1.687350" bigVal="0.395347" smallVal="21.050699" bigSig="0.031690">

$infile = $ARGV[0];
@flds = split("/",$infile);
$xmlname = $flds[-1];

open (IF, $infile) or die "Could not open the input XML file $infile\n";
$count = 0;
while (<IF>) {
    next unless (/<mevPerDac smallSig=/);
    $count++;
    s/=/ /g;
    s/\"/ /g;
    @f = split;
    %vals = ();
    $vals{$f[1]} = $f[2];
    $vals{$f[3]} = $f[4];
    $vals{$f[5]} = $f[6];
    $vals{$f[7]} = $f[8];
    push @big,$vals{bigVal};
    push @small,$vals{smallVal};
}

print STDERR "$0: $count lines read from $xmlname\n";

# do sigma clipping of outliers, if necessary

print STDERR "$0: starting interative sigma clip of BIG diode values\n";
@bigin = @big;
$nit = 0;
while ($nit < 3) {
    $nit++;
    @bigout = sigmaclip(@bigin);
    last if ($#bigout == $#bigin);
    @bigin = @bigout;
}
@big = @bigout;

print STDERR "$0: starting interative sigma clip of SMALL diode values\n";
@smallin = @small;
$nit = 0;
while ($nit < 3) {
    $nit++;
    @smallout = sigmaclip(@smallin);
    last if ($#smallout == $#smallin);
    @smallin = @smallout;
}
@small = @smallout;

@bigsort = sort { $a <=> $b } @big;
@smallsort = sort { $a <=> $b } @small;
$bc = scalar(@big);
$sc = scalar(@small);
$bigtot = 0;
$smalltot = 0;
foreach (@big) { $bigtot += $_};
foreach (@small) { $smalltot += $_};
$bigmed = $bigsort[int($bc/2)];
$smallmed = $smallsort[int($sc/2)];
$bigavg = sprintf "%9.6f",$bigtot/$bc;
$smallavg = sprintf "%10.6f",$smalltot/$sc;
print "$xmlname\t$bc\t$bigavg\t$bigmed\t$sc\t$smallavg\t$smallmed\n";

sub sigmaclip {
    my @inp = @_;
    my $tot = 0;
    my $totsq = 0;
    my $count = scalar(@inp);

    foreach $val (@inp) { 
	$tot += $val;
	$totsq += $val * $val;
    }
    $avg = $tot/$count;
    $rms = sqrt($totsq/$count);

    @out = ();
    foreach $i (0..$#inp) {
	$sigma = abs($inp[$i]-$avg)/$rms;
	if ($sigma < 5) { push @out,$inp[$i] }
	else { printf STDERR "$0:\tclipped datum $i = $inp[$i] at %.1fx rms %.3f from the average %.3f\n",$sigma,$rms,$avg};
    }
    return @out;
}
