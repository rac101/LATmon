#!/usr/local/bin/perl -w

#h3. Mission Week 110 {anchor:MW110} (2010/189 - 2010/195)
#h3. Mission Week 109 {anchor:MW109} (2010/182 - 2010/188)

#0 2008-05-29 150
#1 2008-06-05 157
#2 2008-06-12 164
#3 2008-06-19 171

#date +"%F %T" ; date --date="+ 3 days" +"%F 00:00:00"

for $mw (0..1000) { 
    $cmd = "date --date=\"2008-05-29 + $mw weeks\" +\"%Y/%j\""; $o1 = `$cmd`; chomp $o1;
    $cmd = "date --date=\"2008-05-29 + $mw weeks + 6 days\" +\"%Y/%j\""; $o2 = `$cmd`;  chomp $o2;
    $cmd = "date --date=\"2008-05-29 + $mw weeks\" +\"%F\""; $o3 = `$cmd`; chomp $o3;
    $cmd = "date --date=\"2008-05-29 + $mw weeks + 6 days\" +\"%F\""; $o4 = `$cmd`;  chomp $o4;
    print "Mission Week $mw ($o1 - $o2) ($o3 - $o4) {anchor:MW$mw}\n";
}
