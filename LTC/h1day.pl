#!/usr/local/bin/perl -w

# get LTC HTR state duty cycle for 1 day
# here is the format of the MnemRet.py command:
# MnemRet.py -b 'YYYY-MM-DD 00:00:00' -e '+1 days' LTCnnHTRSTATE
#
# output to STDOUT will be
# YYYY-MM-DD #0 samples, #1 samples, #all samples for each HTR

# Robert Cameron
# August 2013

# usage: ./h1day.pl YYYY-MM-DD

$date = $ARGV[0];

$htrs = '';
@key = ('00','06','07','01','02','03','04','05','08','09','10','11');
foreach (@key) {$htrs .= " LTC".$_."HTRSTATE" };
$cmd = "MnemRet.py -b '$date 00:00:00' -e '+1 days' $htrs";
print STDERR "$0: run: $cmd\n";
@htr = `$cmd`;

# send results to STDOUT

%on = ('00',0,'06',0,'07',0);
%ct = %on;

foreach (@htr) { 
    next unless (/^VAL/);
    @f = split;
    $h = $f[4];
    $h =~ s/LTC//;
    $h =~ s/HTRSTATE//;
    $ct{$h} += 1;
    $on{$h} += $f[5];
}
$t = '';
foreach (@key) { $t .= "\t$_\t$ct{$_}\t$on{$_}" if ($_ eq '00' or $_ eq '06' or $_ eq '07' or $on{$_}) }; 
print "$date$t\n";
