#!/usr/local/bin/perl -w

# A very simple XML difference script
# Robert Cameron
# 2013 July 22
# 
# call this script with the 2 XML filenames as the first 2 command arguments
# Usage:
# ./xmldiff.pl LAT_config_XML_file_1 LAT_config_XML_file_2 > LAT_config_diff_report 

# use modules
use XML::Simple;

$f1 = $ARGV[0];
$f2 = $ARGV[1];

$totstrips1 = 0;
$totstrips2 = 0;

# create objects
$xml1 = new XML::Simple;
$xml2 = new XML::Simple;

# read XML file
$d1 = $xml1->XMLin($f1);
$d2 = $xml2->XMLin($f2);

foreach $ti (0..15) {
    $t1 = ${$d1->{tower}}[$ti];
    $t2 = ${$d2->{tower}}[$ti];
    foreach $pi (0..35) {
	$p1 = ${$t1->{uniplane}}[35-$pi];
	$p2 = ${$t2->{uniplane}}[35-$pi];
	$l1 = "";
	$l2 = "";
	if ($p1->{stripList}) { $l1 = $p1->{stripList}{strips} };
	if ($p2->{stripList}) { $l2 = $p2->{stripList}{strips} };
	next unless ($l1 or $l2);
	@l1 = split ' ',$l1;
	%l1 = map {$_, 1} @l1;
	@l2 = split ' ',$l2;
	%l2 = map {$_, 1} @l2;
	$totstrips1 += scalar(@l1);
	$totstrips2 += scalar(@l2);
	next if ($l1 eq $l2);
	print "T$ti L$pi:\n";
	unless ($l1) { print "In second XML, $f2 : extra strips: $l2\n"; next };
	unless ($l2) { print "In first XML, $f1 : extra strips: $l1\n"; next };
	$ol1 = "";
	$ol2 = "";
	foreach (@l1) { $ol1 .= "$_ " unless ($l2{$_}) };
	foreach (@l2) { $ol2 .= "$_ " unless ($l1{$_}) };
	if ($ol1) { print "In first XML, $f1 : extra strips: $ol1\n" };
	if ($ol2) { print "In second XML, $f2 : extra strips: $ol2\n" };
    }
}
print "\n\nIn first XML, $f1 : total strip count = $totstrips1\n";
print "In second XML, $f2 : total strip count = $totstrips2\n";
