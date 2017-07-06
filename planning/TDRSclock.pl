#!/usr/bin/env perl

# do a simple "countdown clock" from a web-based TDRSS Forecast Schedule file

# on isoc-ops7, put on the desktop, and in the icon "Properties", set "Open With" the custom command:
# xterm -T TDRSclock -n TDRSclock -ge 95x1 -fa 9x15 -fs 18
# when you click on the desktop icon, choose "Display" as the run option
# and (if you want) set "Always on Top" and "Always on Visible Workspace" on window menu

# Robert Cameron
# July 2016

use warnings;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);

$test = 0; # insert short fake contacts into the schedule
$test = 1 if (@ARGV && $ARGV[0] eq "t"); 

$Term::ANSIColor::AUTORESET = 1;

%tdrs = ('E'=>'TDRS-TDE','W'=>'TDRS-TDW','Z'=>'TDRS-TDZ','S'=>'TDRS-TDS','1'=>'TDRS-171','2'=>'TDRS-275');

$| = 1;

# make day hash, to help linearize contact times
# contact start and stop times are of the form: YYYY/DOY/HH:MM:SS, e.g. 2016/147/18:09:33
# make hash table of cumulative day count keyed by year
# and arrays of years and cumulative day count

$day0 = 0;
for $year (2001..2050) {
    push @year,$year;
    push @day0,$day0;
    $day0{$year} = $day0;
    $day0 += 365;
    $day0++ unless ($year % 4);
}

# Unix seconds at the start of 2001 UTC
$s2001 = 978307200;

LOOP:
#print STDERR "passing LOOP\n";
    @schedule = `/usr/bin/curl http://www.slac.stanford.edu/~rac/transfer/mics.txt 2> /dev/null`;

$now = time() - $s2001;

%f1 = ();
%f2 = ();
%f3 = ();
foreach (@schedule) { 
    next unless (/^20/);
    @f = split;
    $tdrs = $tdrs{$f[-1]};
    $t0 = $f[0];
    $t1 = $f[1];
#    $dt = $f[2];
#    print "$tdrs $t0 $t1\n";
    ($s1, $tt0) = secs($t1);
    next if ($now >= $s1);   # ignore past contacts
    ($s0, $tt0) = secs($t0);
    $f1{$s0} = "$tdrs @ $tt0";
    $f2{$s0} = $s1 - $s0;
    $f3{$s0} = $s1;
}

# insert short fake contacts into the schedule, if "$test" is non-zero

if ($test) { 
    $gmtest = strftime "%Y/%j/%H:%M:%S", gmtime(); 
    ($s0, $tt0) = secs($gmtest);
    $s0 += 10; # fake contact will start in 10 seconds
    $s1 = $s0 + 10;  # fake contact will last for 10 seconds
    $f1{$s0} = "JUNK @ $tt0";
    $f2{$s0} = $s1 - $s0;
    $f3{$s0} = $s1;
}

@ss = sort(keys(%f1));
$i = -1;

#LOOP:
$i++;
die "$0: TDRSS contact schedule file is too old, please update it\n" if ($i > scalar(@ss)); 
$j = $i + 1;
$b0 = $ss[$i];
$c0 = $f1{$b0};
$d0 = $f2{$b0};
$e0 = $f3{$b0};
$b1 = $ss[$j];
$c1 = $f1{$b1};
$d1 = $f2{$b1};

while (1) { 
    sleep 1;
    $now = time() - $s2001;   # now in Unix seconds 
    goto LOOP if ($now > $e0);   # refresh schedule after the end of a contact
    $gmt = strftime "%j/%H:%M:%S", gmtime;   # now in formatted UTC time 
    ($sign, $delta, $dur) = shmd($now, $b0, $d0, $e0);
    $line = "\r$gmt   $sign$delta > $c0 < $dur   Next: $c1 < $d1   ";
    if($sign eq "-"){ print BOLD GREEN $line } else { print BOLD RED $line }
}
print "\n";

##***************************************************************************
sub shmd {
##***************************************************************************

# give signed delta time and duration for a contact, relative to current time

    my ($time, $beg, $dur, $end) = @_;
    $sn = " ";
    $dd = $dur;
    $dt = $beg - $time;
    if ($dt < 0) {            # dt < 0 if now is after contact start
        $sn = "-";
        $dt = $time - $beg;
        $dd = $end - $time;
    }
    $ss = $dt % 60;
    $mm = $dt / 60;
    $dt = sprintf "%02d:%02d",$mm,$ss;
    return ($sn, $dt, $dd);
}

##***************************************************************************
sub secs {
##***************************************************************************

# convert a formatted TDRSS event time to linear seconds and "no-year format"

    my $event = shift;

    $event =~ s/\D/ /g;
    ($y,$doy,$h,$m,$s) = split(' ',$event);
    $sevent = ($day0{$y}+$doy-1)*86400 + $h*3600 + $m*60 + $s;
    return ($sevent, "$doy/$h:$m:$s");
}
