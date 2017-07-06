#!/usr/local/bin/perl -w

# collect daily uptime numbers using Jana's Uptime.py script

# Robert Cameron
# April 2012

# usage: ./tup.pl >> tup.out

# a typical line start from tup.out is:
# 2012-10-07 23:59:55.140074 2012-10-09 00:00:04.140105 86408.000030

# first, find the most recent results in "tup.out"

$wdir = "/nfs/farm/g/glast/u55/rac/LATmetrics/uptime";
@tail = `tail $wdir/tup.out`;
$tail = '';
until ($tail =~ /:/)  { $tail = pop(@tail) };
@f = split(' ',$tail);
($h,$m,$m) = split(':',$f[3]);
$startdate = $f[2];
if ($h > 1) { $startdate = `date --date="$f[2] + 1 day" +"%F"` };
chomp $startdate;
$startsec = `date --date="$startdate 00:00:00" +'"%s"'`;
$startsec =~ s/\D//g;
print STDERR "startdate $startdate & startsec $startsec\n";

$enddate = `date --date="-3 days" +"%F"`;
chomp $enddate;
$endsec = `date --date="$enddate 00:00:00" +'"%s"'`;
$endsec =~ s/\D//g;

$ndays = ($endsec - $startsec)/86400.0; 
if ($ndays > 1) { print STDERR "$0: Working on $ndays days, for day range $startdate to $enddate\n" };

#$cmd = "/nfs/farm/g/glast/u55/rac/LATmetrics/uptime/Uptime.py -b '$startdate' -e '+1 days' -a -x";
print STDERR "$cmd\n";
for $d (0..$ndays-1) { 
    $cmd = "date --date='$startdate + $d day' +'%F'";
#    $cmd = 'date --date="'.$startdate." + $d day".'" +"%F"';
    print STDERR "$cmd\n";
   $startdate = `$cmd`;
    chomp $startdate;
#    $cmd = "/nfs/farm/g/glast/u55/rac/LATmetrics/uptime/Uptime.py -b '$startdate' -e '+1 days' -a -x";
    print STDERR "$startdate\n";
}
