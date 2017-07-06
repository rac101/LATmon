#!/usr/local/bin/perl -w

# get and condense the latest GLAST TDRSS Forecast Schedule
# main code is now wrapped in timeout structure, based on previous runaway example of this script

# Robert Cameron
# July 2016

# usage: ./getTDRSS-try2.pl > mics.txt

# read from: /nfs/slac/g/glast/online/CountdownClock/ics.txt
# which has lines like:
##   Begin         |     End           | Duration | Stn   | (kbps) | Pass  | Service | Ant   | Config
#2016/196/15:10:00 | 2016/196/15:43:00 | 00:33:00 | 275   |      4 |    na | SSAF    | TDRSS | SSC=H01 EventID=7797635 SUPIDEN=A2525MS Service=1
#2016/196/15:10:00 | 2016/196/15:43:00 | 00:33:00 | 275   |      8 |    na | SSAR    | TDRSS | SSC=I18 EventID=7797635 SUPIDEN=A2525MS Service=2
#2016/196/16:45:19 | 2016/196/16:51:12 | 00:05:53 | 275   |      4 |    na | SSAF    | TDRSS | SSC=H01 EventID=7797644 SUPIDEN=A2525MS Service=1
#2016/196/16:45:19 | 2016/196/16:51:12 | 00:05:53 | 275   |      8 |    na | SSAR    | TDRSS | SSC=I18 EventID=7797644 SUPIDEN=A2525MS Service=2
#2016/196/16:56:12 | 2016/196/17:01:43 | 00:05:31 | TDS   |      4 |    na | SSAF    | TDRSS | SSC=H01 EventID=7789249 SUPIDEN=A2525MS Service=1
#2016/196/16:56:12 | 2016/196/17:01:43 | 00:05:31 | TDS   |  40000 |    na | KSAR    | TDRSS | SSC=P01 EventID=7789249 SUPIDEN=A2525MS Service=2
#2016/196/17:09:06 | 2016/196/17:18:35 | 00:09:29 | 171   |      4 |    na | SSAF    | TDRSS | SSC=H01 EventID=7789661 SUPIDEN=A2525MS Service=1
#2016/196/17:09:06 | 2016/196/17:18:35 | 00:09:29 | 171   |  40000 |    na | KSAR    | TDRSS | SSC=P01 EventID=7789661 SUPIDEN=A2525MS Service=2

use File::Basename;
use Try::Tiny;
$bn = basename($0);

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

    %tdrs = ();
    %contacts = ();

    $infile = "/nfs/slac/g/glast/online/CountdownClock/ics.txt";
    open IF, $infile or die "Could not open input ics file $infile\n";

    while (<IF>) { 
	next unless (/^20/);
	s/\|//g;
	@f = split;
	$tdrs = $f[3];

# check for (unlikely) repeat use of TDRS ID (final letter of TDRS name)
	$tdrs_id = chop $tdrs;
	if ($tdrs{$tdrs_id}) {
	    $t0 = $tdrs{$tdrs_id};
	    print STDERR "$bn: TDRS ID=$tdrs_id mismatch between $tdrs and $t0\n" unless ($tdrs eq $t0);
	}
	$tdrs{$tdrs_id} = $tdrs;
	$out = "$f[0] $f[1] $f[2] $tdrs_id\n";
	print $out unless ($contacts{$out});
	$contacts{$out} = 1;
    }
}
