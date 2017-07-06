#!/usr/local/bin/perl -w

# get daily LTC HTR state duty cycle
# here is the format of the MnemRet.py command:
# MnemRet.py -b '-1 days' -e '2012-06-30 00:00:00' LTC00HTRSTATE LTC06HTRSTATE LTC07HTRSTATE
#
# which produces the output:
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC00HTRSTATE  0 (  0)
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC06HTRSTATE  0 (  0)
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC07HTRSTATE  0 (  0)

# output to STDOUT (h067.history) will be
# YYYY-MM-DD #0 samples, #1 samples, #all samples for each HTR

# Robert Cameron
# August 2013

# usage: ./geth067.pl >> htr.history

$htrs = '';
@key = ('00','06','07','01','02','03','04','05','08','09','10','11');
foreach (@key) {$htrs .= " LTC".$_."HTRSTATE" };

# first, find the most recent good results in htr.history

$dir = "/nfs/farm/g/glast/u55/rac/LATmetrics/LTC";

@tail = ();
$nlines = 0;
until ($tail[0] and $tail[0] =~ /^20/) {
    $nlines++;
    @tail = `tail -$nlines $dir/htr.history`;
}
if ($nlines > 1) { print STDERR "$0: needed to tail $nlines lines in htr.history\n" };
@f = split(' ',$tail[0]);
$tdate = $f[0];
$tdate_s = `date --date="$tdate" +"%s"`;

$today = `date +"%F"`;
chomp $today;
$today_s = `date --date="$today" +"%s"`;

$deld = ($today_s - $tdate_s)/86400 - 1;
if ($deld > 1) { print STDERR "$0: processing $deld days from $tdate to $today\n" };

foreach (1..$deld) {
    $date = `date --date="$tdate + $_ days" +"%F"`;
    chomp $date;
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
}
