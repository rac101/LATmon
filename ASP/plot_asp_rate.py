import os
import numpy as num
import pylab_plotter as plot
from read_data import read_data
from parse_timeline import *

_fssc_site = 'http://fermi.gsfc.nasa.gov/ssc/observations/timeline/posting'
_timeline = lambda x : os.path.join(_fssc_site, x, '')

def overlay_intervals(obs_type, color='g', threshold=1e3, target=None):
    address = _timeline(obs_type)
    intervals = get_time_intervals(address, target=target)
    for tstart, tstop in intervals:
        if tstop - tstart > threshold:
            plot.pylab.axvspan(mjd(tstart), mjd(tstop),
                               facecolor=color, alpha=0.5,
                               edgecolor=color)
    return intervals

#grb_ids = read_data('asp_blind_search.txt', ncols=1)[0]
#grb_ids = read_data('blind_search_triggers_24Oct2012.dat', ncols=1)[0]
#grb_ids = read_data('blind_search_triggers_12Jul2013.txt', ncols=1)[0]
#grb_ids = read_data('blind_search_triggers_20Nov2013.txt', ncols=1)[0]
#grb_ids = read_data('blind_search_triggers_26Aug2014.txt', ncols=1)[0]
#grb_ids = read_data('blind_search_triggers_14Mar2015.txt', ncols=1)[0]
#grb_ids = read_data('blind_search_triggers_01Nov2015.txt', ncols=1)[0]
#grb_ids = read_data('blind_search_triggers_13Mar2016.txt', ncols=1)[0]
grb_ids = read_data('blind_search_triggers_24Aug2016.txt', ncols=1)[0]
asp_grbs = read_data('asp_grbs.txt', ncols=1)[0]

npts = len(grb_ids)
win = plot.xyplot(mjd(grb_ids), range(npts), xname='MJD', yname='#trigger')

indx = [num.where(x == grb_ids)[0][0] for x in asp_grbs]
plot.xyplot(mjd(asp_grbs), indx, color='r', oplot=1)

#time, accidentals = read_data('accidentals_vs_time.dat')
#plot.curve(mjd(time), accidentals/1.744e3*2, oplot=1, color='r')

# March 6-7, 2012 X5-class flares
march_sf = (met(datetime.datetime(2012, 3, 6)),
            met(datetime.datetime(2012, 3, 8)))
plot.pylab.axvspan(mjd(march_sf[0]), mjd(march_sf[1]), color='r')

# Crab pointed observation not in FSSC pointed list
crab_2012_pointing = (met(datetime.datetime(2012, 7, 5, 0, 0, 0)),
                      met(datetime.datetime(2012, 7, 8, 12, 38, 01)))
plot.pylab.axvspan(mjd(crab_2012_pointing[0]), mjd(crab_2012_pointing[1]),
                   color='b')

too = overlay_intervals('too', color='g')
pointed = overlay_intervals('pointed', color='b')
ao5 = overlay_intervals('ao5', color='m', target='NADIR', threshold=0)
ao4 = overlay_intervals('ao4', color='m', target='NADIR', threshold=0)
ao3 = overlay_intervals('ao3', color='m', target='nadir', threshold=0)
arr = overlay_intervals('arr', color='c')
#freeze = overlay_intervals('a05', color='y', target='Freeze', threshold=-1)
#cal = overlay_intervals('cal', color='y')

def exclude(grb_ids, intervals):
    ids = []
    for item in grb_ids:
        accept = True
        for tmin, tmax in intervals:
            if tmin < item < tmax:
                accept = False
        if accept:
            ids.append(item)
#    print "excluded grbs:", len(grb_ids) - len(ids)
    return num.array(ids)

my_ids = num.array([x for x in grb_ids if x not in asp_grbs])
nongrb = len(my_ids)
print "non GRBs:", nongrb

my_ids = exclude(my_ids, too)
nontoo = len(my_ids)
print "TOOs:", nongrb - nontoo

my_ids = exclude(my_ids, pointed)
nonpointed = len(my_ids)
print "pointed:", nontoo - nonpointed

my_ids = exclude(my_ids, ao5)
my_ids = exclude(my_ids, ao4)
my_ids = exclude(my_ids, ao3)
nonnadir = len(my_ids)
#print "Nadir:", non_gc_profile-nonnadir
print "Nadir:", nonpointed-nonnadir

my_ids = exclude(my_ids, arr)
nonarr = len(my_ids)
print "ARR:", nonnadir - nonarr

my_ids = exclude(my_ids, (march_sf,))
nonsf = len(my_ids) - 1
print "Solar Flare:", nonarr-nonsf

my_ids = exclude(my_ids, (crab_2012_pointing,))
noncrab = len(my_ids)
print "July 2012 Crab pointing:", nonsf - noncrab

plot.xyplot(mjd(my_ids), range(len(my_ids)), oplot=1, color='g')
win.set_title('ASP Blind Search triggers')
print "Survey mode triggers (green):", len(my_ids)

plot.save('ASP_blind_search_triggers_24Aug2016.png')
