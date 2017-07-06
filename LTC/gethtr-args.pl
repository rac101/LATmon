#!/usr/local/bin/perl -w

# get daily LTC HTR state duty cycle
# here is the format of the MnemRet.py command:
# MnemRet.py -b '-1 days' -e '2012-06-30 00:00:00' LTCnnHTRSTATE
#
# which produces the output:
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC00HTRSTATE  0 (  0)
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC06HTRSTATE  0 (  0)
#VAL: 2013-08-27 05:22:42.417461 (1377580962.417461) LTC07HTRSTATE  0 (  0)

# output to STDOUT (htr.history) will be
# YYYY-MM-DD "HTR #1 samples #all samples" for each HTR

# Robert Cameron
# August 2013

# usage: ./gethtr-args.pl YYYY-MM-DD numdays >> htr.history

$htrs = '';
@key = ('00','06','07','01','02','03','04','05','08','09','10','11');
foreach (@key) {$htrs .= " LTC".$_."HTRSTATE" };

$date0 = $ARGV[0];
$numdays = $ARGV[1];

foreach (0..$numdays) {
    $date = `date --date="$date0 + $_ days" +"%F"`;
    chomp $date;
    $cmd = "MnemRet.py -b '$date 00:00:00' -e '+1 days' $htrs";
#    print STDERR "$0: run: $cmd\n";
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
