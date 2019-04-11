#!/usr/local/bin/python

# simplify history of daily SSR Usage

# typical lines from ssr.history
# Daily Ave  2012 06 16 23 59 58   2012 06 17 23 59 58    126.620 Gbits 86399 sec  > 126.620 Gbits day 1.466 Mbits sec
# Daily Ave  2012 06 17 23 59 58   2012 06 18 23 59 58    128.105 Gbits 86399 sec  > 128.106 Gbits day 1.483 Mbits sec

# Robert Cameron
# June 2018

# usage: ./fssr.py < ssr.history > ssr.simple

import sys
import os
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
    print d.strftime("%F"),f[-6]
