#!/usr/local/bin/python

# check time continuity of history of daily GEM SENT count

# typical lines from gem.sent
#2011-05-01 13 27 28.943126 800780824
#2011-05-02 13 27 26.943128 965220442
#2011-05-03 13 27 23.943135 1130136021

# Robert Cameron
# April 2016

# usage: ./xsent.py < gem.sent

import sys
import datetime as dt
import os

myname = os.path.basename(__file__)

linecount = 0

for line in sys.stdin:
    linecount += 1
    line = line.rstrip('\n')
    if not line.startswith('20'):
        print ("{}: non-standard format for line: {}".format(myname,line))
        continue
    (utc, c) = line.rsplit(' ',1)
    if float(c) < 1:
        print ("{}: unexpected trigger count for line: {}".format(myname,line))
    t = dt.datetime.strptime(utc,"%Y-%m-%d %H %M %S.%f")
    try:
        delt = t - pt
        delts = delt.total_seconds() - 86400
        if delts>15:
            print ("{}: unexpected time jump from {} to {} for line {}".format(myname,putc,utc,line))
    except:
        pass
    pt = t
    putc = utc

print ( "{}: last input line {}, has date and time {}".format(myname,linecount,utc))
