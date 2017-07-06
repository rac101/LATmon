#!/usr/bin/perl -w

# convert Fermi OPS files (TDRSS Forecast Schedule files) to YAML format

# Robert Cameron
# May 2016

# make day hash, to help linearize contact times
# contact start and stop times are of the form: YYYY/DOY HH:MM:SS, e.g. 2016/147 18:09:33
# make hash table of cumulative day count keyed by year; 2008 = 0
# and arrays of years and cumulative day count

use YAML::XS qw(LoadFile);
use POSIX qw(strftime);
use Term::ANSIColor;

$TDRSSfile = "/Users/rac/Documents/GLAST/ISOC/LATmetrics/rsync-depot/outdir/TDRSSschedule.yaml";
$| = 1;

$day0 = 0;
for $year (2001..2030) {
    push @year,$year;
    push @day0,$day0;
    $day0{$year} = $day0;
    $day0 += 365;
    $day0++ unless ($year % 4);
}

# Unix seconds at the start of 2001 UTC
$s2001 = 978307200;
$now = time() - $s2001;
#print "NOW = $now\n";

# convert YAML TDRSS Contact file to perl hash ref
open $fh, '<', $TDRSSfile or die "$0: cannot open TDRSS Contact file: $!";
$cs = LoadFile($fh);

@e = keys($cs);

foreach (@e) { 
    next unless (/SCHEDULEDEVENT/);
    $tdrs = $cs->{$_}->{TDRS};
    $t0 = $cs->{$_}->{EVENTSTART};
    $t1 = $cs->{$_}->{EVENTSTOP};
#    print "$tdrs $t0 $t1\n";
    ($s1, $tt0) = secs($t1);
    next if ($now >= $s1);   # skip past passed contacts
    ($s0, $tt0) = secs($t0);
    $f1{$s0} = "$tdrs @ $tt0";
    $f2{$s0} = $s1 - $s0;
    $f3{$s0} = $s1;
}
#die "$0: TDRSS contact file is too old, please update it\n" unless (scalar(@ss)); 
@ss = sort(keys(%f1));
$i = -1;

LOOP:
$i++;
die "$0: TDRSS contact file is too old, please update it\n" if ($i > scalar(@ss)); 
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
    $gmt = strftime "%j/%H:%M:%S", gmtime;   # now in formatted UTC time 
    goto LOOP if ($now > $e0);   # jump to the next contact after the end of a contact
    ($sign, $delta, $dur) = shmd($now, $b0, $d0, $e0);
    $line = "\r$gmt   $sign$delta > $c0 < $dur   Next: $c1 < $d1   ";
    if($sign eq "-"){print colored ($line,'red')}else{print color 'reset';print $line}
}
print color 'reset';
print "\n";

##***************************************************************************
sub shmd {
##***************************************************************************

# convert an event time into linear seconds

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

# convert an event time into linear seconds

    my $event = shift;

    $event =~ s/\D/ /g;
    ($y,$doy,$h,$m,$s) = split(' ',$event);
    $sevent = ($day0{$y}+$doy-1)*86400 + $h*3600 + $m*60 + $s;
    return ($sevent, "$doy/$h:$m:$s");
}
