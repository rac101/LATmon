#!/usr/local/bin/perl -w

# get hourly Fermi nav telemetry at user-supplied timestamps
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

# usage: ./getnav-targs.pl < input-times-file >> nav.history
# input times shoudl be of the format (1 timestamp per line):
# YYYY-MM-DD HH:MM:SS

# this script truncates numbers in the output

@poskey = ('SG_NAVPOSJ2000_1','SG_NAVPOSJ2000_2','SG_NAVPOSJ2000_3');
@velkey = ('SG_NAVVELJ2000_1','SG_NAVVELJ2000_2','SG_NAVVELJ2000_3');
$nav = '';
foreach (@poskey) { $nav .= " $_" };
foreach (@velkey) { $nav .= " $_" };

foreach $date (<>) {
    chomp $date;
    $cmd = "MnemRet.py -b '$date' -e '+1 seconds' $nav";
    print STDERR "$0: running: $cmd\n";
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
    foreach (@poskey) { $t .= " $sv{$_}" };
    foreach (@velkey) { $t .= " $sv{$_}" };
    print "$ymd $hms $sec$t\n";
}
