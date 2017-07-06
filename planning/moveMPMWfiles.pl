#!/usr/local/bin/perl -w

# copy routine weekly LAT ATS planning and review to my www-ops area

# Robert Cameron
# 2016 January

# make hash table of cumulative day count keyed by year; 2008 = 0
# and arrays of years and cumulative day count
$daycount = 0;
for $year (2008..2090) {
    push @year,$year;
    push @daycount,$daycount;
    $daycount{$year} = $daycount;
    $daycount += 365;
    $daycount++ unless ($year % 4);
}

# find the mission week
$today = `date -u +"%w"`;   # numeric weekday; Thursday = 4.
chomp $today;
$ddays = 11 - $today;
$ddays += 7 if ($today > 4);
$plandate = `date -u --date="+$ddays days" +"%F %Y DOY %j"`;
($y,$py,$y,$pdoy) = split (" ",$plandate);
$ldp = $daycount{$py} + $pdoy;
$ld0 = $daycount{2008} + 150; # mission week 0 = 2008-5-29, 2008 DOY 150
$mpmw = ($ldp - $ld0)/7;

# finally, move the planning and review files to my ops webpage

$mproot = "/u/gl/rac/LATmetrics/planning/";
$odir = '/afs/slac/www/exp/glast/ops';
@files = ("$mpmw.atsfake", "$mpmw.ats0fake", "$mpmw.atsIDsfake", "$mpmw"."plan.fake", "$mpmw"."rev.fake");

foreach (@files) { `cp $mproot/$_ $odir` if (-e "$mproot/$_") };
