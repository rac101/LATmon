#!/usr/local/bin/perl -w

# check for new IOTL reports in the FastCopy archive.

# Robert Cameron
# April 2017

# usage: ./x4iotl.pl
# output goes to STDOUT, STDERR if necessary, and a specific output file in the pairs subdirectory
# can be silent: no output from this script if there is nothing to update, for running in cron with minimal emails

use File::Basename;
use Time::Local;

use strict 'subs';
use strict 'refs';

$sn = basename($0);

# path to my working directory 
#$wdir = "/u/gl/rac/LATmetrics/iotl";

# path to the FastCopy archive of IOTL reports
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# for several recent days' Year/Month/DOY, look for recent IOTL "actual" and "expected" reports
# check multiple days in case there was some multi-day report ingest problem

$date = `date -u +"%F (%j) %T UTC"`;

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
	print "TIME = $fctime and ROOT = $root and TYPE = $type\n";
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
	comppair($afile,$efile,$key);
    }
}

##################################
sub comppair{
    my $actual_file = shift;
    my $expected_file = shift;
    my $IOTLkey = shift;

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

    print "\n>>>> FILE = $IOTLkey\n";
    print " $n_actual lines in ACTUAL file;   FastCopy archive time = $t{$IOTLkey}{'actual'}\n";
    print " $n_expected lines in EXPECTED file; FastCopy archive time = $t{$IOTLkey}{'expected'}\n";

    if($n_expected != $n_actual){
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
	my $time_diff = abs(timediff($time_actual, $time_expected));
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

    print "Number of different lines = $n_differences\n";
    print " Of which, number of different: line numbers = $n_line_number_differences; times = $n_time_differences; commands = $n_command_differences\n";

    print "Time difference summary:\n";
    print " Maximum absolute time difference = $max_time_difference seconds\n";
    print " Time differences (number): 0 ($n_diff0), 1 ($n_diff1), 2 ($n_diff2), 3 ($n_diff3), 4 ($n_diff4), \>4 ($n_more4)\n";

}

##################################
sub timediff{
    my $time1 = shift;
    my $time2 = shift;

    my $year1 = substr($time1, 0, 4);
    my $year2 = substr($time2, 0, 4);
    my $month1 = substr($time1, 5, 2);
    my $month2 = substr($time2, 5, 2);
    my $day1 = substr($time1, 8, 2);
    my $day2 = substr($time2, 8, 2);
    my $hour1 = substr($time1, 11, 2);
    my $hour2 = substr($time2, 11, 2);
    my $min1 = substr($time1, 14, 2);
    my $min2 = substr($time2, 14, 2);
    my $sec1 = substr($time1, 17, 2);
    my $sec2 = substr($time2, 17, 2);

#print "$year1 $month1 $day1\n";
#print "$hour1\n$min1\n$sec1\n";

# Months expected by timegm start at zero!
    $month1--;
    $month2--;

    my $gmtime1 = timegm($sec1, $min1, $hour1, $day1, $month1, $year1);
    my $gmtime2 = timegm($sec2, $min2, $hour2, $day2, $month2, $year2);
#print "gmtime1 = $gmtime1\n";
#print "gmtime2 = $gmtime2\n";

    my $diff = $gmtime1 - $gmtime2;
#print "time difference = $diff\n";

    return ($diff);

}
