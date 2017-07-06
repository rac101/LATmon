#!/usr/local/bin/perl -w

# remove non-number characters from the file, to be compatible with simple read into IDL
#2009-01-01 14:00:00 1230818400 -6458615.0 1351647.250 2109914.250 -2213.225 -6877.500 -2323.044
#2009 01 01 14 00 00 1230818400 -6458615.0 1351647.250 2109914.250 -2213.225 -6877.500 -2323.044

# Robert Cameron
# September 2013

# usage: ./strip.pl nav.YYYY > nav.YYYY-strip

while (<>) {
    s/:/ /g;
    s/\b-/ /g;
    print $_;
}
