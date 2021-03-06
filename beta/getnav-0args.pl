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
# October 2013

# usage: ./getnav-0args.pl >> nav.history

# this script truncates numbers in the output

# first, find the most recent good results in nav.history

$dir = "/nfs/farm/g/glast/u55/rac/LATmetrics/beta";

@tail = ();
$nlines = 0;
until ($tail[0] and $tail[0] =~ /^20/) {
    $nlines++;
    @tail = `tail -$nlines $dir/nav.history`;
}
if ($nlines > 1) { print STDERR "$0: needed to tail $nlines lines in nav.history\n" };
@f = split(' ',$tail[0]);
$tdate = $f[0];
$tdate = `date --date="$f[0] + 1 day" +"%F"`;
chomp $tdate;
$tdate_s = `date --date="$tdate" +"%s"`;

$today = `date +"%F"`;
chomp $today;
$today_s = `date --date="$today" +"%s"`;

$numdays = ($today_s - $tdate_s)/86400;

if ($numdays > 1) { print STDERR "$0: processing $numdays days from $tdate to $today\n" };

@key = ('SG_NAVPOSJ2000_1','SG_NAVPOSJ2000_2','SG_NAVPOSJ2000_3','SG_NAVVELJ2000_1','SG_NAVVELJ2000_2','SG_NAVVELJ2000_3');
$nav = '';
foreach (@key) { $nav .= " $_" };
@velkey = ('SG_NAVVELJ2000_1','SG_NAVVELJ2000_2','SG_NAVVELJ2000_3');

for $d (0..$numdays) {
    @day24 = ();
    for $hr (0..23) {
	$hrs = $d*24 + $hr;
	$date = `date --date="$tdate + $hrs hours" +"%F %T"`;
	chomp $date;
	$cmd = "MnemRet.py -b '$date' -e '+1 seconds' $nav";
#    print STDERR "$0: run: $cmd\n";
	@res = `$cmd`;

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
	foreach (@key) { $t .= " $sv{$_}" };
	push @day24,"$ymd $hms $sec$t\n";
    }
    if ($#day24 == 23) { print @day24 } else { die "$0: ending at $ymd\n" };
}
