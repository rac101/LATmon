#!/usr/bin/perl -w

# example input lines:
# MnemRet: populating t&c database from 1.33b
# MnemRet: adding decom clients for: LHKGEMSENT
# MnemRet: creating PktRetriever
# MnemRet: starting packet retrieval
# VAL: 2010-09-03 13:27:11.618296 (1283520431.618296) LHKGEMSENT                       1939191589 (                1939191589)
# VAL: 2010-09-03 13:27:23.618294 (1283520443.618294) LHKGEMSENT                       1939191589 (                1939191589)
# VAL: 2010-09-03 13:27:35.618297 (1283520455.618297) LHKGEMSENT                       1939191589 (                1939191589)

$sod = 13*3600 + 27*60 +25;
$td = 1e6;
$o = "";

while (<>) {
    next unless (/VAL/);
    s/:/ /g;
    @f = split;
    $t = $f[2]*3600 + $f[3]*60 + $f[4];
    $dd = abs($sod-$t);
    if ($dd < $td) { $o = "$f[1] $f[2] $f[3] $f[4] $f[7]"; $td = $dd };
}
print "$o\n"; 
