#!/usr/bin/env perl

# do a simple "countdown clock" from a web-based TDRSS Forecast Schedule file

# on isoc-ops7, put on tHe desktop, and in the icon "Properties", set "Open With" the custom command:
# xterm -T TDRS -n TDRS -ge 100x1 -fa r14 -fs 24 -bg black

# to run as a clock display in Linux:
# right-click on the desktop icon and select "Open with xterm" or "Open" then "Display"
# then right-click on the xterm title bar and choose "Always on Top" and "Always on Visible Workspace"

# Robert Cameron
# July 2016

# format of contact schedule file
#T1   2016/272 21:13:44  2016/272 21:22:49  171 00:09:05   8k
#T2   2016/272 22:08:56  2016/272 22:16:01  TDS 00:07:05   Ku

use warnings;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);
#use Try::Tiny;

$test = 0; # insert short fake contacts into the schedule
$test = 1 if (@ARGV && $ARGV[0] eq "t"); 

$Term::ANSIColor::AUTORESET = 1;

%tdrs = ('TDE'=>'TDRS-TDE','TDW'=>'TDRS-TDW','TDZ'=>'TDRS-TDZ','TDS'=>'TDRS-TDS','171'=>'TDRS-171','275'=>'TDRS-275');

$| = 1;

# make day hash %day0, to help linearize contact times
# make hash table of cumulative day count keyed by year

$day = 0;
for $year (2001..2090) {
    $day0{$year} = $day;
    $day += 365;
    $day++ unless ($year % 4);
}

# Unix seconds at the start of 2001 UTC
$s2001 = 978307200;

$e0 = 0;

# every second, "overprint" a 1-line summary of the next 2 TDRS contacts 
while (1) { 
    sleep 1;
    $now = time() - $s2001;   # now in Unix seconds 
    if ($now > $e0) {   # refresh schedule after the contact ends
	@sched = getSchedule();
	($c0,$b0,$e0,$d0,$c1,$d1) = procSchedule();
    }
    $gmt = strftime "%j/%H:%M:%Sz", gmtime;   # now in formatted UTC time 
    ($sign, $delta, $dur) = shmd($now, $b0, $d0, $e0);
    $line = "\r$gmt $sign$delta > $c0 < $dur s, Next: $c1 < $d1 s ";
    if($sign eq "-"){ print BOLD GREEN $line } else { print BOLD RED $line }
}
print "\n";

##***************************************************************************
sub getSchedule {
##***************************************************************************

# get the latest TDRSS schedule

    @sched = `/usr/bin/curl http://www.slac.stanford.edu/~rac/transfer/mics.txt 2> /dev/null`;

#    @sched = @_;
#    try {
#	local $SIG{ALRM} = sub { die "alarm\n" };
#	alarm 9;
#	@sched = `/usr/bin/curl http://www.slac.stanford.edu/~rac/transfer/mics.txt 2> /dev/null`;
#	alarm 0;
#    }
#    catch {
#	die $_ unless $_ eq "alarm\n";
#	print STDERR "$0: curl for TDRSS schedule has timed out\n";
#    }
#    finally {
#	return @sched;
#    }
    return @sched;
}

##***************************************************************************
sub procSchedule {
##***************************************************************************

# process the latest TDRSS schedule, and return info about the current and next contacts 

    $now = time() - $s2001;

    %f1 = ();
    %f2 = ();
    %f3 = ();
    foreach (@sched) { 
	next unless (/^T\d+   20/);
	@f = split;
	$tdrs = $tdrs{$f[-3]}? $tdrs{$f[-3]} : "????";
	$tdrs .= " $f[-1]";
	$t0 = "$f[1] $f[2]";
	$t1 = "$f[3] $f[4]";
#    $dt = $f[-2];
#    print "$tdrs $t0 $t1 $dt\n";
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
    die "$0: no TDRS contacts scheduled\n" unless (@ss);
    
    $b0 = $ss[0];    # current TDRS contact start time
    $c0 = $f1{$b0};  # current TDRS contact info and start time
    $d0 = $f2{$b0};  # current TDRS contact duration (seconds)
    $e0 = $f3{$b0};  # current TDRS contact end time
    $b1 = $ss[1];    # next TDRS contact start time
    $c1 = $f1{$b1};  # next TDRS contact info and start time
    $d1 = $f2{$b1};  # next TDRS contact duration (seconds)

    return ($c0,$b0,$e0,$d0,$c1,$d1);
}

##***************************************************************************
sub shmd {
##***************************************************************************

# return signed delta time and duration for a contact, relative to current time

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
