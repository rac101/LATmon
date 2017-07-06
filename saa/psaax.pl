#!/usr/local/bin/perl -w

# find pairs of SAA reports to be compared

# Robert Cameron
# January 2015

# usage: ./psaax.pl

# path to my archive of SAA reports
$rdir = "/u/gl/rac/LATmetrics/saa/reports";

# read the archived report names into a hash
@myrep = `cd $rdir; ls -1 L20*SAA*`;
foreach (@myrep) { chomp; $myrep{$_} = 1 };

# read in the existing list of SAA reports, from the file "SAA.reports"
$wdir = "/u/gl/rac/LATmetrics/saa";
@xr = `cat $wdir/SAA.reports`;
foreach (@xr) { chomp; $xrep{$_} = 1 };
$prev = '';
until ($prev =~ /L20.*SAA/) { $prev = pop @xr };
@f = split ('/',$prev);
$prep = $f[-1];
chomp $prep;
print "$0: latest checked report is $prep\n";

# path to the FastCopy archive of SAA reports 
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# get recent days' Year/Month/DOY
$day0 = `date +"%Y/%m/%j.*"`;
$day1 = `date --date="yesterday" +"%Y/%m/%j.*"`;
$day2 = `date --date="2 days ago" +"%Y/%m/%j.*"`;
$day3 = `date --date="3 days ago" +"%Y/%m/%j.*"`;
$day4 = `date --date="4 days ago" +"%Y/%m/%j.*"`;
$day5 = `date --date="5 days ago" +"%Y/%m/%j.*"`;
$day6 = `date --date="6 days ago" +"%Y/%m/%j.*"`;
$day7 = `date --date="7 days ago" +"%Y/%m/%j.*"`;
chomp $day0;
chomp $day1;
chomp $day2;
chomp $day3;
chomp $day4;
chomp $day5;
chomp $day6;
chomp $day7;

# look for recent SAA reports
@r0 = `find $fcdir/$day0 -name 'L20*SAA*'`;
@r1 = `find $fcdir/$day1 -name 'L20*SAA*'`;
@r2 = `find $fcdir/$day2 -name 'L20*SAA*'`;
@r3 = `find $fcdir/$day3 -name 'L20*SAA*'`;
@r4 = `find $fcdir/$day4 -name 'L20*SAA*'`;
@r5 = `find $fcdir/$day5 -name 'L20*SAA*'`;
@r6 = `find $fcdir/$day6 -name 'L20*SAA*'`;
@r7 = `find $fcdir/$day7 -name 'L20*SAA*'`;
exit unless (@r0 or @r1 or @r2 or @r3 or @r4 or @r5 or @r6 or @r7);
@r = sort (@r7,@r6,@r5,@r4,@r3,@r2,@r1,@r0);

#append the names of new SAA reports, in order, into "SAA.reports".
# and copy new SAA reports into the "reports" subdirectory
foreach (@r) { 
    chomp;
    print "found: $_\n";
    next if ($xrep{$_});
    next unless (/SAA/);
    @f = split('/',$_);
    $rep = $f[-1];
    chomp $rep;
    print "adding new report to 'SAA.reports':\n\t$_\n";
    `echo "$_" >> $wdir/SAA.reports`;
    print "report pair to be compared: $rep and $prep\n" unless ($rep eq $prep);
    $prep = $rep;
    if ($myrep{$rep}) {
	$size0 = `wc $rdir/$rep`;
	@size0 = split('/',$size0);
	$size1 = `wc $_`;
	@size1 = split('/',$size1);
	print "sizes of my $rep and FastCopy version are: $size0[0] and $size1[0]\n";
    }
    print "copying $rep to $rdir\n";
    `cp $_ $rdir`;
}
