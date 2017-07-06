#!/usr/local/bin/perl -w

# XML inspection script, to recover CAL photodiode gains
# Robert Cameron
# 2014 August
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
    next unless (/<mevPerDac smallSig/);
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
    $bigtot += $vals{bigVal};
    $smalltot += $vals{smallVal};
}
$bigavg = sprintf "%9.6f",$bigtot/$count;
$smallavg = sprintf "%10.6f",$smalltot/$count;
@bigsort =sort { $a <=> $b } @big;
@smallsort =sort { $a <=> $b } @small;
$middle = $count/2;
$bigmed = $bigsort[$middle];
$smallmed = $smallsort[$middle];
print "$xmlname\t$count\t$smallmed\t$bigmed\t$smallavg\t$bigavg\n";
 
