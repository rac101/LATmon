#!/usr/local/bin/perl -w

# collect daily uptime numbers using Jana's Uptime.py script

# Robert Cameron
# April 2012

# usage: ./tup.pl >> tup.out

for $bday (-133 .. -50) { 
    $cmd = 'date --date="'.$bday.' days" +"%F 00:00:00"';
    $day = `$cmd`;
    chop $day;
    $cmd = "Uptime.py -b '-1 days' -e '$day' -a -x";
#    print  "$cmd\n";
    @res = `$cmd`;
    foreach (@res) { 
	next unless /Summary/;
	s/Summary: //;
	print $_;
    }
}
