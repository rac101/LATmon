#!/usr/local/bin/perl -w

# check for new IOTL reports in the FastCopy archive.

# Robert Cameron
# April 2017

# usage: ./qx4iotl.pl
# output goes to STDOUT, STDERR if necessary, and a specific output file in the pairs subdirectory
# can be silent: no output from this script if there is nothing to update, for running in cron with minimal emails

# Fermi MW = 0 starts on 2008 May 29, at Unix seconds = 1212019200 (neglecting leap seconds)

use File::Basename;
use Time::Local;

use strict 'subs';
use strict 'refs';

$sn = basename($0);

# sample IOTL filenames:
# IOTL_2017348000000_2017354235959_SCS348A4.txt
# IOTL_2017334150000_2017340235959_SCS334B1.txt

# path to my working directory 
#$wdir = "/u/gl/rac/LATmetrics/iotl";

# path to the FastCopy archive of IOTL reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# for several recent days' Year/Month/DOY, look for recent IOTL "actual" and "expected" reports
# check multiple days in case there was some multi-day report ingest problem

$date = `date -u +"%F (DOY %j) %T UTC"`;

print "$sn: Run Time = $date"; 

foreach $dayold (0..6) { 
    %h = ();
    %k = ();
    %t = ();
    $day = `date --date="$dayold days ago" +"%Y/%m/%j"`;
    chomp $day;
    @r = `find $fcdir/$day.* -name 'IOTL*.txt*.txt'`;
    @r = sort @r;    # if files are repeated on the same day, use the latest files
    printf "\nDay $day: %i IOTL files found in the FastCopy archive\n",scalar(@r);
    next unless (@r);
#    print @r;
    foreach (@r) {
	chomp;
	next unless (/actual/ or /expected/);
	$copy = $_;
#    print "file is $copy\n";
	s/\// /g;
	@f = split;
	$fctime = $f[-2];
	$fctime =~ s/\./:/g;
#	($hour,$minute,$second) = split(':',$fctime);
#	$fcseconds = $hour*3600 + $minute*60 + $seconds;
	s/\./ /g;
	@f = split;
	$type = $f[-2];
	$root = $f[-4];
	($mw,$doff,$ddiff) = rootparse($root);
	$string1 = $doff? " + $doff days" : "";
	$string2 = "(MW $mw$string1 for $ddiff days)";
	print "TIME = $fctime and ROOT = $root $string2 and TYPE = $type\n";
	$h{$root}{$type} = $copy;
#	$s{$root}{$type} = $fcseconds;
	$t{$root}{$type} = $fctime;
	$k{$root} = 1;
    }

    @k = reverse (sort (keys %k));

    foreach $key (@k) {
	unless ($h{$key}{"actual"}) {print "ERROR: ACTUAL version of LAT IOTL file $_ not found!\n"; next};
	unless ($h{$key}{"expected"}) {print "ERROR: EXPECTED version of LAT IOTL file $_ not found!\n"; next};
#    print "\n",$h{$key}{"actual"},"\n",$h{$key}{"expected"},"\n";
	$afile = $h{$key}{"actual"};
	$efile = $h{$key}{"expected"};
	comppair($afile,$efile,$key);      #<<<<< do the checking and reporting in thus subroutine
    }
}

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
	print "\n>>>> FILE = $IOTLkey $string2  <<<<  BAD\n";
	print " $n_actual lines in ACTUAL file;   FastCopy archive time = $t{$IOTLkey}{'actual'}\n";
	print " $n_expected lines in EXPECTED file; FastCopy archive time = $t{$IOTLkey}{'expected'}\n";
	print "ERROR: different number of lines in Actual and Expected files\n";
	return;
    }

# Compare the 2 files line by line

    my $n_line = 0;
    my $n_differences = 0;
    my $n_line_number_differences = 0;
    my $n_time_differences = 0;
    my $n_command_differences = 0;
    
    my $max_time_difference = 0;

# print "Detailed check\n";

    my $n_diff0 = 0;
    my $n_diff1 = 0;
    my $n_diff2 = 0;
    my $n_diff3 = 0;
    my $n_diff4 = 0;
    my $n_more4 = 0;

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
	if($time_diff == 0){$n_diff0++;}
	elsif($time_diff == 1){$n_diff1++;}
	elsif($time_diff == 2){$n_diff2++;}
	elsif($time_diff == 3){$n_diff3++;}
	elsif($time_diff == 4){$n_diff4++;}
	elsif($time_diff > 4){$n_more4++;}
	else {print "Should not be here!\n";}

# Check to see if different. If so, what type of differences.

	$n_differences++ if($line_actual ne $line_expected);
	$n_line_number_differences++ if($line_number_actual ne $line_number_expected);	
    	$n_time_differences++ if($time_actual ne $time_expected);
	$max_time_difference = $time_diff if($time_diff > abs($max_time_difference));
	$n_command_differences++ if($command_actual ne $command_expected);
       
    }

    $score = "GOOD";
    $score = "BAD" if ($n_line_number_differences or $n_command_differences or $max_time_difference > 4);

    print "\n>>>> FILE = $IOTLkey $string2  <<<<  $score\n";
    print " $n_actual lines in ACTUAL file;   FastCopy archive time = $t{$IOTLkey}{'actual'}\n";
    print " $n_expected lines in EXPECTED file; FastCopy archive time = $t{$IOTLkey}{'expected'}\n";

    print "Number of different lines = $n_differences\n";
    print " Of which, number of different: line numbers = $n_line_number_differences; times = $n_time_differences; commands = $n_command_differences\n";

    print "Time difference summary:\n";
    print " Maximum absolute time difference = $max_time_difference seconds\n";
    print " Time differences (number): 0 ($n_diff0), 1 ($n_diff1), 2 ($n_diff2), 3 ($n_diff3), 4 ($n_diff4), \>4 ($n_more4)\n";

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

# Months expected by timegm start at zero
    $doy1--;

    my $gmtime1 = timegm($sec1, $min1, $hour1, 1, 0, $year1) + $doy1*86400;
#print "gmtime1 = $gmtime1\n";

    return ($gmtime1);

}
