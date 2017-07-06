#!/usr/local/bin/perl -w

# for Memory errors found in the first half of the geosaa.pl script, here is the separate second half of the script, 
# to add geo coordinates and the SAA flag to older memory error lines missing those data
# 
#here is the output from make_pretty.py:
#EPU1: 2012-04-12 19:36:52.768670 (1334259412.768670)  Address:  107903824 (0x066e7b50)  Type: 4 (Correctable multi-bit error)
#EPU1: 2012-04-12 19:41:38.640417 (1334259698.640417)  Address:   49624968 (0x02f53788)  Type: 3 (Correctable single-bit error)
# SIU: 2012-04-12 19:42:00.151270 (1334259720.151270)  Address:   93555832 (0x05938c78)  Type: 3 (Correctable single-bit error)
#EPU1: 2012-04-12 21:11:35.271460 (1334265095.271460)  Address:   35725640 (0x02212148)  Type: 3 (Correctable single-bit error)

# Robert Cameron
# April 2012

# usage: ./geosaa-backfill.pl < file-of-deficient errors > file-of-augmented errors

while (<>) { 
    next unless (/20/);
    next if (/ [01]$/); 
    chomp;
    $err = $_;
    @fld = split;
    $cmd = "MnemRet.py -b '-1 seconds' -e '$fld[1] $fld[2]' SGPSBA_LONGITUDE SGPSBA_LATITUDE SACFLAGLATINSAA";
#    print STDERR "$0: About to execute the command: $cmd<<<<<<\n";
    @loc = `$cmd`;
#    print STDERR "$0: The MnemRet.py result is: \n",@loc;
    print $err;
    foreach (keys(%hash)) { $hash{$_} = -9999 };
    if ($loc[4] =~ "VAL" || $loc[5] =~ "VAL" || $loc[6] =~ "VAL") {
	foreach (@loc) {
	    next unless /VAL/;
	    @val = split;
	    $hash{$val[4]} = $val[5];
	}
    }
    print " $hash{SGPSBA_LONGITUDE} $hash{SGPSBA_LATITUDE} $hash{SACFLAGLATINSAA}\n";
}
#print "\n";
