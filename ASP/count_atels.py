see: http://glast.stanford.edu/cgi-bin/viewcvs/users/jchiang/ASP_statistics_scripts/count_atels.py

import urllib

address = 'http://www-glast.stanford.edu/cgi-bin/pub_rapid'
lines = urllib.urlopen(address).readlines()
atels = []
for line in lines:
    if line.find('http://www.astronomerstelegram.org/') != -1:
        atels.append(line.strip())

#for item in atels:
#    print item

print "# ATels:", len(atels)

address = 'http://fermi.gsfc.nasa.gov/ssc/data/access/lat/msl_lc/'
lines = urllib.urlopen(address).readlines()
monitored = []
for line in lines:
    if line.find('RA =') != -1:
        monitored.append(line.strip())

#for item in monitored:
#    print item

print "# monitored sources:", len(monitored)
