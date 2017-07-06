#!/usr/local/bin/perl -w

# Robert Cameron
# January 2015

# usage: ./saax.pl

# path to the FastCopy archive of SAA reports 
$fcdir = "/nfs/farm/g/glast/u23/ISOC-flight/Archive/fcopy";

# get today's and yesterday's Year/Month/DOY
$today = `date +"%Y/%m/%j.*/"`;
#$yesterday = `date --date="yesterday" +"%Y/%m/%j.*/"`;
$yesterday = `date --date="4 days ago" +"%Y/%m/%j.*/"`;
chomp $today;
chomp $yesterday;

# read the previously examined reports into a hash
$wdir = "/u/gl/rac/LATmetrics/saa";
@prep = `cat $wdir/SAA.reports`;
%prep = ();
foreach (@prep) { $prep{$_} = 1 };

# sort the previously examined reports into time receipt order
@sprep = sort (@prep);
@f = split('/',$sprep[-1]);
$lastprep = $f[-1];

# also sort the previously examined reports by filename
@fnprep = ();
foreach (@prep) { 
    @f = split('/',$_);
    push @fnrep,$f[-1];
}
@sfnprep = sort (@fnprep);
$lastfn = $fnprep[-1];

# find the most recent previously examined report in my report archive
# could select on FastCopy receipt time, or on YYYYDOY in the report name.
# most of the time these will be consistent. But not always.
# So check both methods, and report any discrepancy.

print STDERR "$0: last report $lastfn does not match last FastCopy delivery $sprep[-1]\n" unless ($lastprep eq $lastfn);

# go by report filename as the default for identifying the latest report in the archive.

# get today's and yesterday's SAA reports
@rep1 = `find $fcdir/$today -name 'L201*SAA*'`;
@rep2 = `find $fcdir/$yesterday -name 'L201*SAA*'`;
exit unless (@rep1 or @rep2);
@rep = (@rep1,@rep2);
print "\n$0: recent SAA reports:\n",@rep;

# remove previously processed reports from the recent list, to identify new reports
@newrep = ();
foreach (@rep) { push @newrep,$_ unless ($prep{$_}) };
exit unless (@newrep);
print "\n$0: new SAA reports:\n",@newrep;

# previously processed reports will be in my archive, but new reports will not.
