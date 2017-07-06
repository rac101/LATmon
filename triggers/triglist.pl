#!/usr/bin/perl -w

use Time::Local;

# example input lines:
# VAL: 2010-09-03 13:27:11.618296 (1283520431.618296) LHKGEMSENT                       1939191589 (                1939191589)
# VAL: 2010-09-03 13:27:23.618294 (1283520443.618294) LHKGEMSENT                       1939191589 (                1939191589)
# VAL: 2010-09-03 13:27:35.618297 (1283520455.618297) LHKGEMSENT                       1939191589 (                1939191589)

# example output line:
# MnemRet.py -b "2011-05-01 13:27:00" -e "+45 seconds" LHKGEMSENT | sample.pl
# MnemRet.py -b "2011-05-02 13:27:00" -e "+45 seconds" LHKGEMSENT | sample.pl
# MnemRet.py -b "2011-05-03 13:27:00" -e "+45 seconds" LHKGEMSENT | sample.pl

# here is our baseline time: the start of 2010 UTC in seconds since the start of 1970
# noric01:rac> date -u -d '2010-01-01 00:00:00' +%s
# 1262304000

# 13:27:25 UTC is when Eric Siskind measures the value of LHKGEMSENT
# 13:27:25 = 48445 SOD.

$sod = 13*3600 + 27*60 +25;

# find today, or yesterday if unlikely to have today's data at time $sod

($sec,$min,$hour,$mday,$mon,$year) = gmtime();
$hms = $sec + $min*60 + $hour*3600;
$now = timegm(0,0,0,$mday,$mon,$year);
$nowdate = sprintf "%4d-%02d-%02d", $year+1900, $mon+1, $mday;
if ($hms - $sod < 30000) { $now -= 86400 };

# find last valid date in gem.sent (time is within 30 seconds of $sod)

$wdir = "/u/gl/rac/LATmetrics";
$gemfile = "$wdir/triggers/gem.sent";
open (GF, $gemfile);
@gs = <GF>;
foreach (reverse @gs) {
    @f = split;
    $date = $f[0];
    last if (abs($sod - $f[1]*3600 - $f[2]*60 - $f[3]) < 30);
}
#print STDERR scalar(@gs),"$0: lines read from $gemfile : the last valid date is $date\n";
($y,$m,$d) = split /-/,$date;
$y -= 1900;
$m--;
$then = timegm(0,0,0,$d,$m,$y);
$ndays = ($now - $then)/86400;

die "$0: $gemfile is up to date. Ending.\n" unless ($ndays);

if ($ndays != 1) { print STDERR "$0: running program for $ndays days from $date to $nowdate\n" };

foreach (1..$ndays) {
    $then += 86400;
    ($sec,$min,$hour,$mday,$mon,$year) = gmtime($then);
    $year += 1900; ## $year is number of years since 1900
    $mon++;
    $command = sprintf "MnemRet.py -b '%04d-%02d-%02d 13:27:00' -e '+45 seconds' LHKGEMSENT | $wdir/triggers/sample.pl",$year,$mon,$mday;
#    print STDERR "$0: running.....$command\n";
    $result = `$command`;
    print $result;
}
