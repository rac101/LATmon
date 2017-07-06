#!/usr/local/bin/perl -w

# check time continuity of history of Fermi LAT on-board SAA polygon vertex coordinates

# archive lines begin with: 
#"2017-04-18 23:09:54.540072",1492556994.540072,

# use the linear Unix seconds value

# input from STDIN

# Robert Cameron
# May 2017

# usage: ./xxpoly.pl < history.new.poly
# or:
# usage: ./xxpoly.pl < history1.poly

# intialize to the start of the mission (June 2008)

$week = 7 * 86400;
$prev = 1213857947 - $week;
$prevdate = "";

# read in the history file one line at a time

while (<>) {
    next unless (/20/);
    @val = split;
    $t = $val[2];
    $dt = ($t - $prev - $week);
    if (abs($dt) > 7200) {
#	$dd = sprintf "%5.1f", ($t - $prev)/86400.0;
	$dd = sprintf "%3i", ($t - $prev)/86400.0;
	$flag = "";
	if ($dd > 31) { $flag = "*"x($dd/30) }; 
#	print "$0: time difference = $dd days from $prevdate to $val[0] $val[1] $flag\n";
	$val[0] =~ s/"//;
	print "$0: time difference = $dd days from $prevdate to $val[0] $flag\n";
    }
    $prev = $t;
#    $prevdate = "$val[0] $val[1]";
    $prevdate = $val[0];
}

$t = time();
$dt = ($t - $prev - $week);
if (abs($dt) > 7200) {
    $dd = sprintf "%.1f", ($t - $prev)/86400.0;
    $dd = sprintf "%3i", ($t - $prev)/86400.0;
    $flag = "";
    if ($dd > 31) { $flag = "*"x($dd/30) }; 
    print "$0: time difference = $dd days from $prevdate to NOW $flag\n";
}
