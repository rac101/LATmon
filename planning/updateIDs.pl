#!/usr/local/bin/perl -w

# update runIDs and transIDs in a weekly LAT ATS
# needed input: runID and transactionID database file

# Robert Cameron
# 2016 March

# usage updateIDs.pl < oldATSfile > newATSfile

use Getopt::Long;
use File::Basename;

$sn = basename($0);

my $track = 0;
GetOptions ("track" => \$track) # flag: 1 = update database file with runID and tranID bounds from this ATS
    or die("$sn: Error in command line arguments\n");

# ID history file contains simple flat text database of runIDs and tranIDs from previous ATS plans
# record format:
#1454453166 2016-02-02 2016/033:22:46:06 UTC GLAST_EPH_2016032_2016092_00.txt L2016032SAA.00 402 49244 49349 2108 2110
$mproot = "/u/gl/rac/LATmetrics/planning";
$histfile = "$mproot/LATATSfake.history";
@hist = `cat $histfile`;
exit unless (@hist);
print STDERR "$sn: ".scalar(@hist)." lines read from the makeATS database file:\n  $histfile\n";
foreach (@hist) {
    next if (/Make/);
    @v = split;
    next unless (@v > 9);
#    $mw = $v[6];
#    $runid0{$mw} = $v[7];
#    $runid1{$mw} = $v[8];
#    $tranid0{$mw} = $v[9];
#    $tranid1{$mw} = $v[10];
    $r = $v[8];
    $t = $v[10];
}
$r0 = $r + 1;
$t0 = $t + 1;

# look for "LMEMTRANID=n," and "LPARUNID=n," 
# find MW NNN by searching for "for mission week NNN"
# find ephem filename by searching for "// GLAST_EPH_20..."
# find SAA filename by searching for "// L20..SAA.."
# find runtime XXX by searching for "LAT weekly ATS generated at XXX UTC"
#$runtime = `date -u +"%s %F %Y/%j:%T UTC"`; chomp $runtime;
while (<>) {
    if (/ATS generated at (.+ UTC).+ for mission week (.+)$/) { $runtime = $1; $mpmw = $2; print $_; next };
    if (/^.. (GLAST_EPH_20.+)$/) { $ephemfile = $1; print $_; next };
    if (/^.. (L20.+SAA.+)$/) { $saafile = $1; print $_; next };
    if (/LPARUNID=/) { $r++; $_ =~ s/LPARUNID=.+, LPADBID/LPARUNID=$r, LPADBID/; print $_; next };
    if (/LMEMTRANID=/) { $t++; $_ =~ s/LMEMTRANID=.+, LMEMDEST/LMEMTRANID=$t, LMEMDEST/; print $_; next };
    print $_;
}

if ($track) { 
    open (DF, ">>", $histfile) or die "$sn: Could not open the runID and tranID database file: $histfile\n";
    print DF "$runtime\t$ephemfile\t$saafile\t$mpmw\t$r0\t$r\t$t0\t$t\n";
    close DF;
    print STDERR "$sn: updated ATS runID and tranID database file:\n  $histfile\n";
}
