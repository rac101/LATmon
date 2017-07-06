#! /usr/bin/env python2.5
#

import sys
import getopt
import datetime
import traceback

from quarks.database.dbconfig import DbConfig

from ISOC import SiteDep, utility
from ISOC.TlmUtils.DecomHldbInterface import DecomHlDb
from ISOC.RawArchive.RawArchive import PktRetriever
from ISOC.TlmUtils.Decom import DecomList
from ISOC.ProductUtils import ProductSpan

def usage():
    print """
NAME
    TriggerRate.py - Calculates the Trigger Rate (GEM sent rate) in Hz

SYNOPSIS
    TriggerRate.py [OPTIONS]

OPTIONS
    -b, --beg
        Specifies the beginning of the time interval to process.
        Can be an absolute time specification of the form
        'YYYY-MM-DD hh:mm:ss[.uuuuuu]', a relative specification of
        the form '[+-]N [seconds|minutes|hours|days]' where N is an
        integer, or the keyword 'now'.  Note that it is an error to
        specify two relative endpoints.

    -e, --end
        Specifies the end of the time interval to process.  See -b.

    -r, --run
        Use the start/end times of the specified run as the retrieval interval

    -d, --day
        Calculate daily averages

    -w, --week
        Calculate weekly averages

    -n, --nocreep
        Daily/weekly timespan start times will not creep forward.  See NOTE.

    -i, --interpolate
        Interpolate the trigger rate

    -v, --verbose
        Dump the counters as you do the math

    -h, --help
        Displays this information.

NOTE        
    The --day and --week options will endeavor not to double count.  The next timespan will
    begin where the previous timespan left off, thus preserving continuity.  (If you total
    up the daily triggers over a specific time period, you will get the same answer as if you
    asked for the total over that same time period.  The result of this behavior is that the
    beginning of the timespan will slowly creep forward at the rate of about 6 - 8 seconds per day.
    If you run over the course of a week, the timespan will shift by about a minute
    (see example timespans below).

    If you are running over short time spans (say, a week or less), then the forward creep in your
    1 day timespan does not affect the overall calculation much, but it will give a different answer
    (by something significantly less than the average rate tims the drift, 1.5 kHz * 60 seconds)
    because your phasing with respect to McIlwainL will change, which is a way of saying that the
    average trigger rate is not the instantaneous rate.

    The script provides a switch (-n --nocreep) that changes this default behavior and does not allow
    the timespan start time to creep.  It will always start the next daily (weekly) timespan as close
    to 24 hours (24 hours * 7 days) after the start of the timepsan specified by the --beg field as
    it can get.  The tradeoff is that now, you will not be able to simply add up the triggers to get
    the total.  There will be some under/over counting happening on each given day (week).

    To illustrate, if I were to go back and calculate day 2011-07-03 00:00:00 to 2011-07-04 00:00:00,
    I would get a different number of triggers because this individual day will actually try to
    start at 00:00:00 whereas the last day of my timespan, though it's technically the same day,
    has crept forward.  The difference is 1069 events.

Daily average over a timespan starting at 2011-06-24 00:00:00 - 2011-07-03 00:00:00
 Daily Ave (2011-06-24 23:59:56 - 2011-06-26 00:00:06) :        161559988 triggers / 86410 sec
 Daily Ave (2011-06-26 00:00:06 - 2011-06-27 00:00:15) :        162596180 triggers / 86408 sec
 Daily Ave (2011-06-27 00:00:15 - 2011-06-28 00:00:25) :        162484751 triggers / 86409 sec
 Daily Ave (2011-06-28 00:00:25 - 2011-06-29 00:00:34) :        162140692 triggers / 86409 sec
 Daily Ave (2011-06-29 00:00:34 - 2011-06-30 00:00:44) :        162082865 triggers / 86410 sec
 Daily Ave (2011-06-30 00:00:44 - 2011-07-01 00:00:53) :        162937442 triggers / 86408 sec
 Daily Ave (2011-07-01 00:00:53 - 2011-07-02 00:01:03) :        164370936 triggers / 86410 sec
 Daily Ave (2011-07-02 00:01:03 - 2011-07-03 00:01:12) :        163435380 triggers / 86409 sec
 Daily Ave (2011-07-03 00:01:12 - 2011-07-04 00:01:22) :        163651130 triggers / 86409 sec
     Total (2011-06-24 23:59:56 - 2011-07-04 23:59:57) :       1628946958 triggers / 864001 sec

One day total:
     Total (2011-07-03 00:00:02 - 2011-07-04 00:00:00) :        163652199 triggers / 86398 sec

"""

class TriggerRateHandler(object):
    def __init__(self,label=None,span=None):
        
        self.label = label
        self.span  = span

        self.t0 = None
        self.t1 = None

        self.totcnt = 0
        self.totsec = None

        self.presec = None
        self.precnt = None

        self.verbose = False
        self.nocreep = False

    def setVerbose(self, verbose):
        self.verbose = verbose

    def setNocreep(self, nocreep):
        self.nocreep = nocreep
        
    def update( self, decomitem ):
        try:
            time, cnt = decomitem.getTimeAndValue()
            self.t1 = datetime.datetime.utcfromtimestamp(int(time)) 
            if self.verbose:
                print " %s %s %s"%(self.label[0],self.t1, cnt),
            
            # Initialize times first time through
            if self.totsec is None:
                self.t0     = self.t1
                self.presec = time
                self.precnt = cnt
                self.totcnt = 0
                self.totsec = 0
                if self.verbose:
                    print ""
                return

            cdiff = cnt  - self.precnt
            tdiff = time - self.presec

            # If we miss more than 429496 seconds (4 days) of data (time to roll over at 10 kHz),
            # beware of rollovers (this should never happen)
            if tdiff > 429496:
                print "WARNING! Time difference larger than 429496 sec, beware of rollover!!!"

            # Capture packet counter rollover and FSW counter reset
            if cdiff < 0:
                # For a normal rollover, self.precnt is probably within 1M of 0xffffffff.
                # Then it's a normal rollover and we account using bit rollover techniques.
                # Otherwise the counters were reset by a reboot and so self.precnt is actually 0.

                if (0xffffffff - self.precnt) < 1000000:
                    cdiff += 0xffffffff
                else:
                    cdiff = cnt
                 
            self.totcnt += cdiff
            self.totsec += tdiff

            self.presec = time
            self.precnt = cnt

            if self.verbose:
                print "(%s %s %4i %4.1f) (%10i %10i)"%\
                      (self.t0, self.t1, cdiff,tdiff,self.totcnt,self.totsec)

            # If we've crossed a span boundary,
            # print summary and reset counters
            if self.span is not None:
                if self.t1 - self.t0 >= self.span:
                    self.summarize()
                    self.totcnt = 0
                    self.totsec = 0
                    if self.nocreep:
                        self.t0 += self.span
                    else:
                        self.t0 = self.t1

        except:
            traceback.print_exc( file=sys.stdout )

    def summarize(self):
        Hz = self.totcnt/self.totsec
#        kHz = Hz/1e3

        print "%10s (%s - %s) : %16.0f triggers / %i sec -> %11.1f Hz"%\
              (self.label,self.t0, self.t1,self.totcnt,self.totsec,Hz)
        
def TriggerRate():
    # set some reasonable defaults
    archdir   = SiteDep.get( 'RawArchive', 'archdir' )
    scid      = SiteDep.getint( 'DEFAULT', 'scid' )
    tnc_dbi   = SiteDep.get( 'DEFAULT', 'dbi' )
    dbrel     = SiteDep.get( 'DEFAULT', 'dbrel' )
    run       = None
    nocreep   = None
    verbose   = None
    t0str     = '-10 minutes'
    t1str     = 'now'
    tpad      = 5.0
    uhandlers = [None,None,TriggerRateHandler(label="Total")]
    
    # get the command-line arguments
    if len( sys.argv ) == 1:
        usage()
        return
    else:
        try:
            opts, args = getopt.getopt(sys.argv[1:], 'b:e:r:dwnvh', \
                                       ['beg=','end=','run=',
                                        'day','week','nocreep','verbose','help'])
        except getopt.GetoptError,e:
            print e
            print 'try "TriggerRate.py --help" for usage information.'
            return
        
    for o, a in opts:
        if o in ( '-h', '--help' ):
            usage()
            return
        if o in ( '-b', '--beg' ):
            t0str = a
        if o in ( '-e', '--end' ):
            t1str = a
        if o in ( '-r', '--run' ):
            run = int( a )
        if o in ( '-d', '--day' ):
            one_day = datetime.timedelta(days=1)
            uhandlers[0]=TriggerRateHandler(label="Daily Ave",span=one_day)
        if o in ( '-w', '--week'):
            one_week = datetime.timedelta(weeks=1)
            uhandlers[1]=TriggerRateHandler(label="Weekly Ave",span=one_week)
        if o in ( '-n', '--nocreep'):
            nocreep = True
        if o in ( '-v', '--verbose' ):
            verbose = True

    for h in uhandlers:
        if h: h.setVerbose(verbose)
        if h: h.setNocreep(nocreep)

    # if a run has been specified, retrieve the start/end times
    # from the database
    if run is not None:
        t0str, t1str = utility.getRunSpan( run, SiteDep.get( 'MakeRetDef',
                                                             'runs_dbi' ) )
        if t0str is None:
            print 'TriggerRate: run %09d not found' % run
            return
        print 'TriggerRate: retrieving data for run %09d %s --> %s' %\
              ( run, t0str, t1str )
    
    # get double-precision reps of the timespan endpoints
    t0, t1 = ProductSpan.getspan( t0str, t1str )

    # back up the start-time of the retrieval so we have values at t0
    t0ret = t0 - tpad

    # extend the end-time of the retrieval to allow sampled output to end at
    # the user-specified time
    t1ret = t1 + tpad

    # get a database connection for the telemetry meta-data
    db = DbConfig.fromConfigParser( SiteDep, tnc_dbi )

    # build the decom stack for the telemetry
    print 'TriggerRate: populating t&c database from %s' % dbrel
    tlmdb = DecomHlDb( db )
    tlmdb.populate( source=scid, release=dbrel )
    mnems = tlmdb.getMnemList( ['LHKGEMSENT'] )
    decom = DecomList( mnems, tlmdb=tlmdb )
    
    # set up the decom clients
    for handler in uhandlers:
        if handler: decom.addClient( handler, (mnems[0].name(),) )

    # retrieve the data for the specified timespan
    try:
        print 'TriggerRate: creating PktRetriever'
        pktret = PktRetriever( t0ret, t1ret, decom.getAPIDS(), archdir, scid )
        pktret.addClient( decom )
        print 'TriggerRate: starting packet retrieval'
        pktret.retrievePkts()
    except Exception, e:
        print str(e)
        return

    uhandlers[2].summarize()

if __name__ == '__main__':
    try:
        TriggerRate()
    except:
        traceback.print_exc( file=sys.stdout )
        sys.exit( 1 )
