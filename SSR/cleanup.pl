#!/usr/local/bin/perl -w

# remove unwanted punctuation from data files

# Robert Cameron
# August 2014

# usage: STDIN | ./cleanup.pl | STDOUT

while (<>) { 
    if (/WARNING/) { print $_; next };
    next unless (/Daily Ave/);
    s/[-:\/\(\)]/ /g;
    print $_;
}
