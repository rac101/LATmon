#!/usr/bin/perl -w

# example input lines:
# VAL: 2010-09-03 13:27:11.618296 (1283520431.618296) LHKGEMSENT                       1939191589 (                1939191589)
# VAL: 2010-09-03 13:27:23.618294 (1283520443.618294) LHKGEMSENT                       1939191589 (                1939191589)
# VAL: 2010-09-03 13:27:35.618297 (1283520455.618297) LHKGEMSENT                       1939191589 (                1939191589)


# here is our baseline time: the start of 2010 UTC in seconds since the start of 1970
# noric01:rac> date -u -d '2010-01-01 00:00:00' +%s
# 1262304000

# 13:27:25 UTC is when Eric Siskind measures the value of LHKGEMSENT
# 13:27:25 = 48445 SOD.

$t0 = 1262304000; 
$d = 86400;
$sod = 13*3600 + 27*60 +25;

foreach (0..730) {
    $t = $t0 + $sod + ($d*$_);
    ($sec,$min,$hour,$mday,$mon,$year) = gmtime($t);
    $year += 1900; ## $year is number of years since 1900
    $mon++;
    $k = sprintf "%04d-%02d-%02d",$year,$mon,$mday;
    $h{$k} = $t;
    $d{$k} = 1e6;
}

while (<>) {
    next unless (/VAL/);
    s/\(//;
    s/\)//;
    @f = split;
    unless ($h{$f[1]}) { print STDERR "key not found in hashtable: \n",$f[1]; next };
    $dd = abs($h{$f[1]}-$f[3]);
    if ($dd < $d{$f[1]}) { $gh{$f[1]} = "$f[2] $f[5]"; $d{$f[1]} = $dd };
}

#@k = sort(keys(%gh));
foreach (sort(keys(%gh))) { print "$_ $gh{$_}\n" }; 

#printf "%04d-%02d-%02d %02d:%02d:%02d\n",$year,$mon,$mday,$hour,$min,$sec;
$hour = 0;
$min = 0;
$sec = 0;
