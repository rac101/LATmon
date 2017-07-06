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

# first, find the most recent good results in h067.history

#$dir = "/nfs/farm/g/glast/u55/rac/LATmetrics/LTC";

#@tail = ();
#$nlines = 0;
#until ($tail[0] and $tail[0] =~ /^20/) {
#    $nlines++;
#    @tail = `tail -$nlines $dir/h067.history`;
#}
#if ($nlines > 1) { print STDERR "$0: needed to tail $nlines lines in h067.history\n" };
#@f = split(' ',$tail[0]);
#$tdate = sprintf "%04i-%02i-%02i",@f[8,9,10];
#if ($f[11] > 20) { $tdate = `date --date="$tdate + 1 day" +"%F"` };
#chomp $tdate;
#$tdate_s = `date --date="$tdate" +"%s"`;
#
#$today = `date +"%F"`;
#chomp $today;
#$today_s = `date --date="$today" +"%s"`;

#$deld = ($today_s - $tdate_s)/86400;
#if ($deld > 1) { print STDERR "$0: processing $deld days between $tdate and $today\n" };

$date ="2013-08-01";

$cmd = "MnemRet.py -b '$date 00:00:00' -e '+1 days' LTC00HTRSTATE LTC06HTRSTATE LTC07HTRSTATE";
#print STDERR "$0: About to execute the command: $cmd\n";
@htr = `$cmd`;

# send results to STDOUT

%on = ();
%ct = %on;

foreach (@htr) { 
    next unless (/^VAL/);
    @f = split;
    $h = $f[4];
    $h =~ s/LTC0//;
    $h =~ s/HTRSTATE//;
    $ct{$h} += 1;
    $on{$h} += $f[5];
}
print "$date\t0\t$ct{'0'}\t$on{'0'}\t6\t$ct{'6'}\t$on{'6'}\t7\t$ct{'7'}\t$on{'7'}\n";
