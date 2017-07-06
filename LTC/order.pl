#!/usr/local/bin/perl -w

# re-order LTC HTR results from htr.history
#
# output to STDOUT will be
# YYYY-MM-DD #0 samples, #1 samples, #all samples for each HTR

# Robert Cameron
# August 2013

# usage: ./order.pl < htr.history

@key = ('00','06','07','01','02','03','04','05','08','09','10','11');

# send results to STDOUT

while (<>) {
    %on = ('00',0,'06',0,'07',0);
    %ct = %on;
    @f = split;
    $date = $f[0];
    $nkeys = (@f - 1)/3;
    foreach $k (0..$nkeys-1) {
	$keypos = $k*3 + 1;
	$ctpos = $keypos + 1;
	$onpos = $keypos + 2;
	$key = $f[$keypos];
	$ct{$key} = $f[$ctpos];
	$on{$key} = $f[$onpos];
    }
    $t = '';
    foreach (@key) { $t .= "\t$_\t$ct{$_}\t$on{$_}" if ($_ eq '00' or $_ eq '06' or $_ eq '07' or $on{$_}) }; 
    print "$date$t\n";
}
