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
# August 2013

# usage: ./getnav-2args.pl start-YYYY-MM-DD end-YYYY-MM-DD >> nav.history

# this script truncates numbers in the output

@key = ('SG_NAVPOSJ2000_1','SG_NAVPOSJ2000_2','SG_NAVPOSJ2000_3','SG_NAVVELJ2000_1','SG_NAVVELJ2000_2','SG_NAVVELJ2000_3');
$nav = '';
foreach (@key) { $nav .= " $_" };

$date0 = $ARGV[0];
$date0s = `date --date="$date0" +"%s"`;
$date1 = $ARGV[1];
$date1s = `date --date="$date1" +"%s"`;
$numdays = ($date1s - $date0s)/86400.0;
print STDERR "$0: running for $numdays days\n";

for $d (0..$numdays) {
    for $hr (0..23) {
	$hrs = $d*24 + $hr;
	$date = `date --date="$date0 + $hrs hours" +"%F %T"`;
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
	    $hms = sprintf "$h:$m:%02d",$s;
	    $sec = $f[3];
	    $sec =~ s/\(//;
	    $sec =~ s/\)//;
	    $sec = int($sec);
	    $f[5] .= ' ';
	    $f[5] =~ s/0+ /0/;
	    $sv{$f[4]} = $f[5];
	}
	$t = '';
	foreach (@key[3,4,5]) { $sv{$_} = sprintf "%.4f",$sv{$_} };
	foreach (@key) { $t .= " $sv{$_}" };
	print "$ymd $hms $sec$t\n";
    }
}
