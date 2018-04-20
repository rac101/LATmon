#!/usr/local/bin/perl -w

# check new IOTL reports in the FastCopy archive.

# Robert Cameron
# April 2017

# usage: ./qx4iotl.pl [--days=N] [-d=N]
# output goes to STDOUT, STDERR if necessary, and a specific output file in the pairs subdirectory
# can be silent: no output from this script if there is nothing to update, for running in cron with minimal emails

# Fermi MW = 0 starts on 2008 May 29, at Unix seconds = 1212019200 (neglecting leap seconds)

use File::Basename;
use Time::Local;
use Getopt::Long;
use Try::Tiny;

use strict 'subs';
use strict 'refs';

$sn = basename($0);

try {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 90;
    main();
    alarm 10;
}
catch {
    die $_ unless $_ eq "alarm\n";
    print STDERR "$0: Try timed out\n";
}
finally {
#    print "done\n";
};

#####################################
sub main {

    $days = 6;   # the number of past days to check for IOTL reports
    $dTmax = 4;  # the maximum allowable time difference, in seconds, between actual and expected LAT commands
    GetOptions ('days=i' => \$days);

# sample IOTL filenames:
# IOTL_2017348000000_2017354235959_SCS348A4.txt
# IOTL_2017334150000_2017340235959_SCS334B1.txt

# path to my working directory 
#$wdir = "/u/gl/rac/LATmetrics/iotl";

# path to the FastCopy archive of IOTL reports
    $fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# for the most recent $days number of days' Year/Month/DOY, 
# look for recent IOTL "actual" and "expected" reports
# need to check multiple days in case there was a multi-day report ingest problem

    $date1 = `date -u +"%F (DOY %j) %T UTC"`;
    $date2 = `date -R`;
    $date3 = `date +"(DOY %j) %Z"`;
    chomp $date2;
    chomp $date3;

    print "$sn: Run Time = $date2 $date3 = $date1"; 

    foreach $dayold (0..$days) { 
	%h = ();
	%k = ();
	%t = ();
	$day = `date --date="$dayold days ago" +"%Y/%m/%j (%F)"`;
	chomp $day;
	($day1,$date2) = split (" ",$day); 
	@r = `find $fcdir/$day1.* -name 'IOTL*.txt*.txt'`;
	@r = sort @r;    # if files are repeated on the same day, use the latest files
	printf "\nDay $day: %i IOTL files found in the FastCopy archive\n",scalar(@r);
	next unless (@r);
#       print @r;
	foreach (@r) {
	    chomp;
	    next unless (/actual/ or /expected/);
	    $copy = $_;
#           print "file is $copy\n";
	    s/\// /g;
	    @f = split;
	    $fctime = $f[-2];
	    $fctime =~ s/\./:/g;
#	    ($hour,$minute,$second) = split(':',$fctime);
#	    $fcseconds = $hour*3600 + $minute*60 + $seconds;
	    s/\./ /g;
	    @f = split;
	    $type = $f[-2];
	    $root = $f[-4];
	    ($mw,$doff,$ddiff) = rootparse($root);
	    $string1 = $doff? " + $doff days" : "";
	    $string2 = "(MW $mw$string1 for $ddiff days)";
	    print "TIME = $fctime UTC and ROOT = $root $string2 and TYPE = $type\n";
	    $h{$root}{$type} = $copy;
#	    $s{$root}{$type} = $fcseconds;
	    $t{$root}{$type} = $fctime;
	    $k{$root} = 1;
	}

	@k = reverse (sort (keys %k));

	foreach $key (@k) {
	    unless ($h{$key}{"actual"}) {print "ERROR: ACTUAL version of LAT IOTL file $_ not found!\n"; next};
	    unless ($h{$key}{"expected"}) {print "ERROR: EXPECTED version of LAT IOTL file $_ not found!\n"; next};
#           print "\n",$h{$key}{"actual"},"\n",$h{$key}{"expected"},"\n";
	    $afile = $h{$key}{"actual"};
	    $efile = $h{$key}{"expected"};
	    comppair($afile,$efile,$key);      #<<<<< do the checking and reporting in this subroutine
	}
    }  # end of day loop
}  # end of main sub

##################################
sub comppair{
    my $actual_file = shift;
    my $expected_file = shift;
    my $IOTLkey = shift;

    ($mw,$doff,$ddiff) = rootparse($IOTLkey);
    $string1 = $doff? " + $doff days" : "";
    $string2 = "(MW $mw$string1 for $ddiff days)";

    open(ACTUAL_FILE, $actual_file) or die "Cannot open ACTUAL file: $actual_file\n";
    @af = <ACTUAL_FILE>;
    close(ACTUAL_FILE);

    open(EXPECTED_FILE, $expected_file) or die "Cannot open EXPECTED file: $expected_file\n";
    @ef = <EXPECTED_FILE>;
    close(EXPECTED_FILE);

# number of lines in files
    my $n_actual = scalar(@af);
    my $n_expected = scalar(@ef);
    my $line ="";
    my $line_actual;
    my $line_expected;

    if($n_expected != $n_actual){
	print "\n>>>> FILE = $IOTLkey $string2  <<<< ****  BAD\n";
	print " $n_actual lines in ACTUAL file;   FastCopy archive time = $t{$IOTLkey}{'actual'}\n";
	print " $n_expected lines in EXPECTED file; FastCopy archive time = $t{$IOTLkey}{'expected'}\n";
	print "ERROR: different number of lines in Actual and Expected files\n";
	return;
    }

# Compare the 2 files line by line

    my $n_line = 0;
    my $n_differences = 0;
    my $n_line_num_diff = 0;
    my $n_time_diff = 0;
    my $n_cmd_diff = 0;
    
    my $max_time_diff = 0;

# print "Detailed check\n";

    my $n_dt0 = 0;
    my $n_dt1 = 0;
    my $n_dt2 = 0;
    my $n_dt3 = 0;
    my $n_dt4 = 0;
    my $n_dtmore = 0;

    for (0..$#af) {
	$line_actual = $af[$_];
	$line_expected = $ef[$_];
	
	chomp $line_actual;
	chomp $line_expected;

	my $line_number_actual = substr($line_actual, 0, 6);
	my $line_number_expected = substr($line_expected, 0, 6);

	my $time_actual = substr($line_actual, 7, 19);
	my $time_expected = substr($line_expected, 7, 19);

	my $command_actual = substr($line_actual, 27);
	my $command_expected = substr($line_expected, 27);

# get time difference in seconds
# Should probably use an array!
	my $time_diff = abs(timeparse($time_actual) - timeparse($time_expected));
	if($time_diff == 0){$n_dt0++;}
	elsif($time_diff == 1){$n_dt1++;}
	elsif($time_diff == 2){$n_dt2++;}
	elsif($time_diff == 3){$n_dt3++;}
	elsif($time_diff == 4){$n_dt4++;}
	elsif($time_diff > 4){$n_dtmore++;}
	else {print STDERR "Should not be on this line!\n";}

# Check to see if different. If so, what type of differences.

	$n_differences++ if($line_actual ne $line_expected);
	$n_line_num_diff++ if($line_number_actual ne $line_number_expected);	
    	$n_time_diff++ if($time_actual ne $time_expected);
	$max_time_diff = $time_diff if($time_diff > abs($max_time_diff));
	$n_cmd_diff++ if($command_actual ne $command_expected);
       
    }

    $score = "GOOD";
    $score = "BAD" if ($n_line_num_diff or $n_cmd_diff or ($max_time_diff > $dTmax));

    print "\n>>>> FILE = $IOTLkey $string2  <<<< **** $score\n";
    print " $n_actual lines in ACTUAL file;   FastCopy archive time = $t{$IOTLkey}{'actual'}\n";
    print " $n_expected lines in EXPECTED file; FastCopy archive time = $t{$IOTLkey}{'expected'}\n";

    print "Number of different lines = $n_differences\n";
    print " Of which, number of different: line numbers = $n_line_num_diff; times = $n_time_diff; commands = $n_cmd_diff\n";

    print "Time difference summary:\n";
    print " Maximum absolute time difference = $max_time_diff seconds\n";
    print " Time differences (number): 0 ($n_dt0), 1 ($n_dt1), 2 ($n_dt2), 3 ($n_dt3), 4 ($n_dt4), \>4 ($n_dtmore)\n";

}

##################################
sub rootparse{

# sample strings:
# IOTL_2017348000000_2017354235959_SCS348A4
# IOTL_2017334150000_2017340235959_SCS334B1

    my $root_string = shift;
    ($junk,$t0,$t1,$junk) = split('_',$root_string);
    $utc0 = timeparse2($t0);
    $utc1 = timeparse2($t1);
    $mw1 = ($utc0 - 1212019200)/(86400.0*7.0);
    $dutc = ($utc1 - $utc0)/86400.0;
    $mw0 = int($mw1);
    $mwd = ($mw1 - $mw0)*7.0;
    $mwd = abs($mwd) < 0.001? sprintf "%.0f", $mwd : sprintf "%.3f", $mwd;
    $daydiff = abs($dutc - int($dutc+0.5)) < 0.001? sprintf "%.0f", $dutc : sprintf "%.3f", $dutc;
    return($mw0, $mwd, $daydiff);
}

##################################
sub timeparse{

# Get linear UTC seconds from a date-time string

    my $time1 = shift;

    my $year1 = substr($time1, 0, 4);
    my $month1 = substr($time1, 5, 2);
    my $day1 = substr($time1, 8, 2);
    my $hour1 = substr($time1, 11, 2);
    my $min1 = substr($time1, 14, 2);
    my $sec1 = substr($time1, 17, 2);

#print "Y-M-D / H:M:S = $year1-$month1-$day1 / $hour1:$min1:$sec1\n";

# Months expected by timegm start at zero!
    $month1--;

    my $gmtime1 = timegm($sec1, $min1, $hour1, $day1, $month1, $year1);
#print "gmtime1 = $gmtime1\n";

    return ($gmtime1);

}

##################################
sub timeparse2{

# Get linear UTC seconds from a date-time string that has DOY

    my $time1 = shift;

    my $year1 = substr($time1, 0, 4);
    my $doy1 = substr($time1, 4, 3);
    my $hour1 = substr($time1, 7, 2);
    my $min1 = substr($time1, 9, 2);
    my $sec1 = substr($time1, 11, 2);

#print "Y-DOY / H:M:S = $year1-$doy1 / $hour1:$min1:$sec1\n";

# Days-Of-Year expected by timegm start at zero!
    $doy1--;

    my $gmtime1 = timegm($sec1, $min1, $hour1, 1, 0, $year1) + $doy1*86400;
#print "gmtime1 = $gmtime1\n";

    return ($gmtime1);

}
