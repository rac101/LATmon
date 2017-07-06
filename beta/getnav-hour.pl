#!/usr/local/bin/perl -w

# get hourly Fermi nav telemetry
# here is the format of the MnemRet.py command:
# MnemRet.py -b '2012-06-30 00:00:00' -e '+1 seconds' SG_NAVPOSJ2000_1 SG_NAVPOSJ2000_2 SG_NAVPOSJ2000_3 SG_NAVVELJ2000_1 SG_NAVVELJ2000_2 SG_NAVVELJ2000_3
#
# which produces the output:
#VAL: 2012-01-01 00:00:00.340076 (1325376000.340076) SG_NAVPOSJ2000_1      -6773038.500000000000 (     -6773038.500000000000)
#VAL: 2012-01-01 00:00:00.340076 (1325376000.340076) SG_NAVPOSJ2000_2       -621852.687500000000 (      -621852.687500000000)
#VAL: 2012-01-01 00:00:00.340076 (1325376000.340076) SG_NAVPOSJ2000_3      -1256559.625000000000 (     -1256559.625000000000)
#VAL: 2012-01-01 00:00:00.340076 (1325376000.340076) SG_NAVVELJ2000_1            93.731758117676 (           93.731758117676)
#VAL: 2012-01-01 00:00:00.340076 (1325376000.340076) SG_NAVVELJ2000_2         -6993.077636718750 (        -6993.077636718750)
#VAL: 2012-01-01 00:00:00.340076 (1325376000.340076) SG_NAVVELJ2000_3          2974.773925781250 (         2974.773925781250)

# output to STDOUT (htr.history) will be
# YYYY-MM-DD HH:MM:SS p1 p2 p3 v1 v2 v3

# Robert Cameron
# February 2014

# usage: ./getnav-hour.pl >> nav.history

# this script truncates numbers in the output

# first, find the most recent good results in nav.history

$dir = "/u/gl/rac/LATmetrics/beta";

@tail = ();
$nlines = 0;
until ($tail[0] and $tail[0] =~ /^20/) {
    $nlines++;
    @tail = `tail -$nlines $dir/nav.history`;
}
if ($nlines > 1) { print STDERR "$0: needed to tail $nlines lines in nav.history\n" };
@f = split(' ',$tail[0]);
($tailhour,$junk,$junk) = split(':',$f[1]);
$taildate = "$f[0] $tailhour:00:00";
$taildate_s = `date -u --date="$taildate" +"%s"`;

# bring the file "up to date", i.e. 2 days ago

$yesterday = `date --date="2 days ago" +"%F %T"`;
$yesterday_s = `date --date="2 days ago" +"%s"`;
chomp $yesterday_s;

$hours = int(($yesterday_s - $taildate_s)/3600);

if ($hours > 1) { print STDERR "$0: processing $hours hours from $taildate to $yesterday\n" };

@poskey = ('SG_NAVPOSJ2000_1','SG_NAVPOSJ2000_2','SG_NAVPOSJ2000_3');
@velkey = ('SG_NAVVELJ2000_1','SG_NAVVELJ2000_2','SG_NAVVELJ2000_3');
$nav = '';
foreach (@poskey) { $nav .= " $_" };
foreach (@velkey) { $nav .= " $_" };

for $h (1..$hours) {
    ($junk,$junk,$hour,$mday,$mon,$year) = gmtime($taildate_s + $h*3600);
    $year += 1900;
    $mon++;
    $date = sprintf "%4d-%02d-%02d %02d:00:00",$year,$mon,$mday,$hour;
    $cmd = "MnemRet.py -b '$date' -e '+1 seconds' $nav";
#    print STDERR "$0: running: $cmd\n";
    @res = `$cmd`;
    unless (@res) { print STDERR "$0: no command result returned for time $date\n"; next };

# send results to STDOUT
	
    %sv = ();
    
    foreach (@res) {
	next unless (/^VAL/);
	@f = split;
	$ymd = $f[1];
	$hms = $f[2];
	($h,$m,$s) = split(':',$hms);
	$hms = sprintf "%02d:%02d:%02d",$h,$m,$s;
	$sec = $f[3];
	$sec =~ s/\(//;
	$sec =~ s/\)//;
	$sec = int($sec);
	$f[5] .= ' ';
	$f[5] =~ s/0+ /0/;
	$sv{$f[4]} = $f[5];
    }
    foreach (@velkey) { $sv{$_} = sprintf "%.4f",$sv{$_} };
    $t = '';
    foreach (@poskey) { $t .= " $sv{$_}" };
    foreach (@velkey) { $t .= " $sv{$_}" };
    $out = "$ymd $hms $sec$t\n";
    @out = split(' ',$out);
    if (scalar(@out) == 9 ) { print $out };
}
