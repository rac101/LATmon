#! /usr/bin/env python3
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
    SsrUsage.py - Calculates the SSR usage in Gbits/day and Mbits/s

SYNOPSIS
    SsrUsage.py [OPTIONS]

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

    -v, --verbose
        Dump the counters as you do the math

    -h, --help
        Displays this information.

"""

class SsrUsageHandler(object):
    def __init__(self,label=None,span=None):
        
        self.label = label
        self.span  = span

        self.t0 = None
        self.t1 = None

        self.totpkt = None
        self.totsec = None

        self.presec = None
        self.precnt = None

        self.verbose = False

    def setVerbose(self, verbose):
        self.verbose = verbose
        
    def update( self, decomitem ):
        try:
            time, cnt = decomitem.getTimeAndValue()
            self.t1 = datetime.datetime.utcfromtimestamp(int(time)) 
            if self.verbose:
                print " %s %s %5i"%(self.label[0],self.t1, cnt),
            
            # Initialize times first time through
            if self.totsec is None:
                self.t0     = self.t1
                self.presec = time
                self.precnt = cnt
                self.totpkt = 0
                self.totsec = 0
                if self.verbose:
                    print ""
                return

            cdiff = cnt  - self.precnt
            tdiff = time - self.presec

            # Capture packet counter rollover
            if cdiff < 0: cdiff += 0xffff

            # If we miss more than 1 minute of data,
            # beware of rollovers
            if tdiff > 61:
                print "WARNING! %s %s : %i s and %i counts between SLGIOLATPKTCNT samples: missed counter rollover?"%\
                      (self.presec,self.t1,tdiff,cdiff)

            self.totpkt += cdiff
            self.totsec += tdiff

            self.presec = time
            self.precnt = cnt

            if self.verbose:
                print "(%4i %4.1f) (%6i %8.1f)"%\
                      (cdiff,tdiff,self.totpkt,self.totsec)

            # If we've crossed a span boundary,
            # print summary and reset counters
            if self.span is not None:
                if self.t1 - self.t0 >= self.span:
                    self.summarize()
                    self.totpkt = 0
                    self.totsec = 0
                    self.t0 = self.t1

        except:
            traceback.print_exc( file=sys.stdout )

    def summarize(self):
        bytes = self.totpkt*1088
        bits  = bytes*8
        Mbits = bits/1e6
        Gbits = bits/1e9
        days  = self.totsec / (60*60*24)
        Gbits_day = Gbits/days
        Mbits_sec = Mbits/self.totsec

        print "%10s (%s - %s) : %7.3f Gbits/%i sec -> %7.3f Gbits/day %5.3f Mbits/sec"%\
              (self.label,self.t0, self.t1,Gbits,self.totsec,Gbits_day,Mbits_sec)
        
def SsrUsage():
    # set some reasonable defaults
    archdir   = SiteDep.get( 'RawArchive', 'archdir' )
    scid      = SiteDep.getint( 'DEFAULT', 'scid' )
    tnc_dbi   = SiteDep.get( 'DEFAULT', 'dbi' )
    dbrel     = SiteDep.get( 'DEFAULT', 'dbrel' )
    run       = None
    verbose   = None
    t0str     = '-10 minutes'
    t1str     = 'now'
    tpad      = 5.0
    uhandlers = [None,None,SsrUsageHandler(label="Total")]
    
    # get the command-line arguments
    if len( sys.argv ) == 1:
        usage()
        return
    else:
        try:
            opts, args = getopt.getopt(sys.argv[1:], 'b:e:r:dwvh', \
                                       ['beg=','end=','run=',
                                        'day','week','verbose','help'])
        except getopt.GetoptError,e:
            print e
            print 'try "SsrUsage.py --help" for usage information.'
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
            uhandlers[0]=SsrUsageHandler(label="Daily Ave",span=one_day)
        if o in ( '-w', '--week'):
            one_week = datetime.timedelta(weeks=1)
            uhandlers[1]=SsrUsageHandler(label="Weekly Ave",span=one_week)
        if o in ( '-v', '--verbose' ):
            verbose = True

    for h in uhandlers:
        if h: h.setVerbose(verbose)

    # if a run has been specified, retrieve the start/end times
    # from the database
    if run is not None:
        t0str, t1str = utility.getRunSpan( run, SiteDep.get( 'MakeRetDef',
                                                             'runs_dbi' ) )
        if t0str is None:
            print 'SsrUsage: run %09d not found' % run
            return
        print 'SsrUsage: retrieving data for run %09d %s --> %s' %\
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
    print 'SsrUsage: populating t&c database from %s' % dbrel
    tlmdb = DecomHlDb( db )
    tlmdb.populate( source=scid, release=dbrel )
    mnems = tlmdb.getMnemList( ['SLGIOLATPKTCNT'] )
    decom = DecomList( mnems, tlmdb=tlmdb )
    
    # set up the decom clients
    for handler in uhandlers:
        if handler: decom.addClient( handler, (mnems[0].name(),) )

    # retrieve the data for the specified timespan
    try:
        print 'SsrUsage: creating PktRetriever'
        pktret = PktRetriever( t0ret, t1ret, decom.getAPIDS(), archdir, scid )
        pktret.addClient( decom )
        print 'SsrUsage: starting packet retrieval'
        pktret.retrievePkts()
    except Exception, e:
        print str(e)
        return

    uhandlers[2].summarize()

if __name__ == '__main__':
    try:
        SsrUsage()
    except:
        traceback.print_exc( file=sys.stdout )
        sys.exit( 1 )
