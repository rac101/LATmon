#!/usr/local/bin/perl

# watch my other scipts running by cron, to see if any have gone rogue
# this script can be run once per hour by cron
# this script has no file dependencies, and is wrapped in a Try timeout

# Robert Cameron
# July 2016

# usage: ./watch.pl

# my process lines will look like: 
#16144 ?        S      0:03 /usr/local/bin/perl -w /afs/slac/package/pinger/autotrace.pl

# if you get an email from watch.pl warning that you have some runaway jobs in cron:
# 1. login to the SLAC farm
# 2. ssh to lnxcron
# 3. ps -ax    # to confirm that the job IDs reported in the email are running and using excessive CPU time
# 4. kill NNNNN   # where NNNNN is the runaway job ID reported in the email from watch.pl
# 5. ps -ax    # to confirm that you have correctly killed the runaway job NNNNN
# 6. exit   # logoff from lnxcron

use warnings;
use File::Basename;
use Try::Tiny;
#$sn = basename($0);

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 15;
    main();
    alarm 0;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: timed out\n";
}
finally {
#    print "done\n";
};

sub main {

    @p = `ps ax | grep "rac/" | grep bin`;
    exit unless (@p);

    foreach (@p) { 
#	print STDERR "$0: found process: $_";
	@f = split;
	$t = $f[3];
	unless ($t =~ /:/) {
	    print STDERR "$0: cannot read time in process: $_";
	    next;
	}
	($m,$t) = split(":",$t);
	print STDERR "$0: rogue process?:\n  $_" if ($m > 0);
    }
}
