#!/usr/local/bin/python

# simplify history of daily average trigger rate

# typical lines from trigrate.jana
# Daily Ave 2018 07 03 23 59 58 2018 07 05 00 00 07 166198936 triggers / 86409 sec > 1923.4 Hz
# Daily Ave 2018 07 04 23 59 56 2018 07 06 00 00 05 165727581 triggers / 86409 sec > 1917.9 Hz

# Robert Cameron
# July 2018

# usage: ./ftrig.py < trigrate.jana > trigrate.jana.txt

import sys
#import os
import datetime

#myname = os.path.basename(__file__)

for line in sys.stdin: 
    if 'Daily Ave' not in line:
#        print ( "{}: Unexpected line: {}".format(myname,line))
        continue
    f = line.split()
    d0 = "{}-{}-{}".format(*f[2:])
    d = datetime.datetime.strptime(d0,"%Y-%m-%d")
    if float(f[5]) > 12:
        d += datetime.timedelta(days=1)        
#    d = "{}".format(d)
    print d.strftime("%F"),f[-2]
