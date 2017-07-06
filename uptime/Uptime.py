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

LIMTOPMODE = {0:"TERMINAL", 1:"QUIESCENT", 2:"CALIBRATION", \
              3:"DIAGNOSTIC", 4:"PHYSICS", 5:"PHYSICS_SAA", \
              6:"TOO", 7:"TOO_SAA", 8:"ARR", 9:"ARR_SAA",  \
              10:"HOLD", 11:"BOOT", 12:"OFF"}
LPASTATE = {0:"IDLE", 1:"RUNNING", 2:"STOPPING",\
            3:"UNKNOWN"}
LCISTATE = {0:"IDLE", 1:"RUNNING", 2:"STOPPING",\
            3:"UNKNOWN"}

def usage():
    print """
NAME
    Uptime.py - Calculates the LAT uptime

SYNOPSIS
    Uptime.py [OPTIONS]

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

    -m, --mode
        Determine what percentage of the time the LAT is in a particular LIM mode

    -s, --saa
        Determine what percentage of the time the LAT is in SAA (and therefore, quiescent)

    -p, --lpa
        Determine the percentage of the time the LAT is in a particular LPA state

    -c, --lci
        Determine the percentage of the time the LAT is in a particular LCI state

    -w, --pwr
        Determine the power state of the LAT (DAQ on/off)

    -a, --all
        Report on all mode, saa, lpa, lci states

    -x, --exc
        Output format suitable for Excel

    -v, --verbose
        Dump the counters as you do the math

    -h, --help
        Displays this information.

"""

class UptimeHandler(object):
    def __init__(self,label=None,span=None):
        
        self.label = label
        self.span  = span

        self.t0 = None
        self.t1 = None

        self.t_beg =None
        self.t_end = None

        self.modes = None
        self.last_mode = None        
        self.mode_data = {}

        self.lpastates = None
        self.last_lpa = None
        self.lpa_data = {}

        self.lcistates = None
        self.last_lci = None
        self.lci_data = {}
        
        self.saa_data = None
        self.last_saa = None

        self.pwr_data = None
        self.last_pwr = None

        self.verbose = False
        self.csv = False

        self.saa_report = False
        self.mode_report = True
        self.lpa_report = False
        self.lci_report = False
        self.pwr_report = False
        
    def setVerbose(self, verbose):
        self.verbose = verbose

    def setCsv(self, csv):
        self.csv = csv

    def setModes(self, modes, mode_report):
        self.modes = modes
        self.mode_report = mode_report

    def setSaa(self, saa_report):
        self.saa_report = saa_report

    def setLpa(self,lpastates,lpa_report):
        self.lpastates = lpastates
        self.lpa_report = lpa_report

    def setLci(self,lcistates,lci_report):
        self.lcistates = lcistates
        self.lci_report = lci_report

    def setPwr(self, pwr_report):
        self.pwr_report = pwr_report

    def update( self, decomitem ):
        try:
            time, val = decomitem.getTimeAndValue()
            name = decomitem.getName()
            self.t1 = datetime.datetime.utcfromtimestamp(time)
            self.t_end = time

            # Initialize the span time if first packet
            if self.t0 is None:
                self.t0 = self.t1
                return 

            if self.t_beg is None:
                self.t_beg = self.t_end

            # Update based on mnemonic
            if (name.find('LIMTOPMODE') >= 0) and self.mode_report:
                self.update_mode(time, val)
            if (name.find('SACFLAGLATINSAA') >= 0) and self.saa_report:
                self.update_saa(time, val)
            if (name.find('LIMTLPASTATE') >= 0) and self.lpa_report:
                self.update_lpa(time, val)
            if (name.find('LIMTLCISTATE') >= 0) and self.lci_report:
                self.update_lci(time, val)
            if (name.find('SE_PAL4_DAQ_INH') >= 0) and self.pwr_report:
                self.update_pwr(time, val)

            # If we've crossed a span boundary,
            # print summary and reset counters
            if self.span is not None:
                if self.t1 - self.t0 >= self.span:
                    self.summarize()
                    self.t0 = self.t1
                    self.mode_data = {}

        except:
            traceback.print_exc( file=sys.stdout )

    def update_mode(self, time, val):
        mode = int(val)

        # Initialize the mode
        if self.last_mode is None:
            self.last_mode = mode

        if self.mode_data.has_key(mode):
            t_start, t_last, sum = self.mode_data[mode]
        else:
            t_start, t_last, sum = (time, time, 0)

        # update the running duty cycle for the selected LIM mode
        if self.last_mode == mode:
            sum = sum + (time - t_last)
            t_last = time
        else:
            self.last_mode = mode
            t_start = time
            t_last = time

        self.mode_data[mode] = (t_start, t_last, sum)

        if self.verbose:
            for mode in self.modes:
                if self.mode_data.has_key(mode):
                    print "%20s %14s: "%(datetime.datetime.utcfromtimestamp(time), \
                                         LIMTOPMODE[mode]), \
                                         self.mode_data[mode][2]

    def update_saa(self, time, val):
        saa = int(val)

        # First time through
        if self.last_saa is None:
            self.last_saa = saa

        # Initialize variables
        if self.saa_data is None:
            t_start, t_last, sum = (time, time, 0)
        else:
            t_start, t_last, sum = self.saa_data

        # SAA entry
        if (self.last_saa == 0) and (saa == 1):
            t_start = time
            t_last = time
            
        # Update sum and t_last while in SAA
        if (self.last_saa == 1) and (saa == 1):
            sum = sum + (time - t_last)    
            t_last = time
                        
        # Update sum on SAA exit and set start/end times to 0
        elif (self.last_saa == 1) and (saa == 0):
            sum = sum + (time - t_last)
            t_start = 0
            t_last = 0

        # Print update if verbose
        if self.verbose:
            print "%20s %14s = %d: %17.1f"%(datetime.datetime.utcfromtimestamp(time), \
                                            'SACFLAGLATINSAA', saa, sum)            
            
        # Update "last" data
        self.last_saa = saa
        self.saa_data = (t_start, t_last, sum)

    def update_lpa(self, time, val):
        lpa = int(val)

        # Initialize the last LPASTATE
        if self.last_lpa is None:
            self.last_lpa = lpa

        if self.lpa_data.has_key(lpa):
            t_start, t_last, sum = self.lpa_data[lpa]
        else:
            t_start, t_last, sum = (time, time, 0)

        # update the running duty cycle for the selected LIM lpa
        if self.last_lpa == lpa:
            sum = sum + (time - t_last)
            t_last = time
        else:
            self.last_lpa = lpa
            t_start = time
            t_last = time

        self.lpa_data[lpa] = (t_start, t_last, sum)

        if self.verbose:
            for lpa in self.lpastates:
                if self.lpa_data.has_key(lpa):
                    print "%20s %14s: "%(datetime.datetime.utcfromtimestamp(time), \
                                         LPASTATE[lpa]), \
                                         self.lpa_data[lpa][2]

    def update_lci(self, time, val):
        lci = int(val)

        # Initialize the last LCISTATE
        if self.last_lci is None:  self.last_lci = lci

        if self.lci_data.has_key(lci):  t_start, t_last, sum = self.lci_data[lci]
        else:  t_start, t_last, sum = (time, time, 0)

        # update the running duty cycle for the selected LIM lpa
        if self.last_lci == lci:
            sum = sum + (time - t_last)
            t_last = time
        else:
            self.last_lci = lci
            t_start = time
            t_last = time

        self.lci_data[lci] = (t_start, t_last, sum)

        if self.verbose:
            for lci in self.lcistates:
                if self.lci_data.has_key(lci):
                    print "%20s %14s: "%(datetime.datetime.utcfromtimestamp(time), \
                                         LCISTATE[lci]), \
                                         self.lci_data[lci][2]

    def update_pwr(self, time, val):
        pwr = int(val)
        
        # Initialize variables
        if self.last_pwr is None: self.last_pwr = pwr
        
        if self.pwr_data is None:  t_start, t_last, sum = (time, time, 0)
        else:  t_start, t_last, sum = self.pwr_data
        

        # Power Off transition 
        if (self.last_pwr == 0) and (pwr == 1):
            t_start = time
            t_last = time
            
        # Update sum and t_last while powered off
        if (self.last_pwr == 1) and (pwr == 1):
            sum = sum + (time - t_last)    
            t_last = time
                        
        # Update sum on Power On and set start/end times to 0
        elif (self.last_pwr == 1) and (pwr == 0):
            sum = sum + (time - t_last)
            t_start = 0
            t_last = 0

        # Print update if verbose
        if self.verbose:
            print "%20s %14s = %d: %17.1f"%(datetime.datetime.utcfromtimestamp(time), \
                                            'SE_PAL4_SIU_INH', pwr, sum)            
            
        # Update "last" data
        self.last_pwr = pwr
        self.pwr_data = (t_start, t_last, sum)
        
    def summarize(self):
        total = self.t_end - self.t_beg
        if self.csv:
            header = "t0 t1 Total " 
            output_string = "Summary:  %s %s %f "% (self.t0, self.t1, total)
            if self.mode_report:
                for mode in self.modes:
                    header += "%s " % LIMTOPMODE[mode]
                    if self.mode_data.has_key(mode):  output_string += "%f "% self.mode_data[mode][2]
                    else:  output_string += "0 "
            if self.saa_report: header += "SAA "; output_string += "%f "% self.saa_data[2]
            if self.lpa_report:
                for lpa in self.lpastates:
                    header += "%s "%LPASTATE[lpa]
                    if self.lpa_data.has_key(lpa):  output_string += "%f " % self.lpa_data[lpa][2]
                    else:  output_string += "0 "
            if self.lci_report:
                for lci in self.lcistates:
                    header += "%s "%LCISTATE[lci]
                    if self.lci_data.has_key(lci):  output_string += "%f " % self.lci_data[lci][2]
                    else:  output_string += "0 "
            print header
            print output_string
        else:
                                                               
            print "%10s (%s - %s) : \n"%(self.label,self.t0, self.t1),
            print "\tTotal Elapsed Time: %14.1f seconds\n"%(total)

            # Print LIMTOPMODE summary
            if self.mode_report:
                print '    ------------------------------------------------------'
                print '     LIM Mode Summary'
                print '    ------------------------------------------------------'
                for mode in self.modes:
                    if self.mode_data.has_key(mode):
                        if total == 0: mode_pct = 0
                        else:  mode_pct = 100*self.mode_data[mode][2]/total
                        print "\t %14s: %17.1f seconds (%3.1f%%)"%(LIMTOPMODE[mode], \
                                                                   self.mode_data[mode][2], \
                                                                   mode_pct)

            # Print SAA summary
            print '    ------------------------------------------------------'
            print '     SAA Summary'
            print '    ------------------------------------------------------'
            if self.saa_report:
                if total == 0:  saa_pct = 0
                else: saa_pct = 100*self.saa_data[2]/total
                print "\t     LAT in SAA:  %17.1f seconds (%3.1f%%)"%(self.saa_data[2], saa_pct)

            # Print LPA summary
            print '    ------------------------------------------------------'
            print '     LPA State Summary'
            print '    ------------------------------------------------------'        
            if self.lpa_report:
                for lpa in self.lpastates:
                    if self.lpa_data.has_key(lpa):
                        if total == 0:  lpa_pct = 0
                        else:  lpa_pct = 100*self.lpa_data[lpa][2]/total
                        print "\t %14s: %17.1f seconds (%3.1f%%)"%(LPASTATE[lpa], \
                                                                   self.lpa_data[lpa][2], \
                                                                   lpa_pct)

            # Print LCI summary
            print '    ------------------------------------------------------'
            print '     LCI State Summary'
            print '    ------------------------------------------------------'                
            if self.lci_report:
                for lci in self.lcistates:
                    if self.lci_data.has_key(lci):
                        if total == 0:  lci_pct = 0
                        else:  lci_pct = 100*self.lci_data[lci][2]/total
                        print "\t %14s: %17.1f seconds (%3.1f%%)"%(LCISTATE[lci], \
                                                                   self.lci_data[lci][2], \
                                                                   lci_pct)
                                                            

        
def Uptime():
    # set some reasonable defaults
    archdir   = SiteDep.get( 'RawArchive', 'archdir' )
    scid      = SiteDep.getint( 'DEFAULT', 'scid' )
    tnc_dbi   = SiteDep.get( 'DEFAULT', 'dbi' )
    dbrel     = SiteDep.get( 'DEFAULT', 'dbrel' )
    run       = None
    verbose   = None
    csv       = None
    mode_report = None
    saa_report  = None
    lpa_report = None
    lci_report = None
    pwr_report = None
    t0str     = '-10 minutes'
    t1str     = 'now'
    tpad      = 5.0
    uhandlers = [None,None,UptimeHandler(label="Uptime")]
    modes   = range(0,13)
    lpastates = range(0,4)
    lcistates = range(0,4)

    # get the command-line arguments
    if len( sys.argv ) == 1:
        usage()
        return 
    else:
        try:
            opts, args = getopt.getopt(sys.argv[1:], 'b:e:r::vhmwspcax', \
                                       ['beg=','end=','run=',
                                        'verbose','help','mode','saa','lpa','lci','pwr','all','exc'])
        except getopt.GetoptError,e:
            print e
            print 'try "Uptime.py --help" for usage information.'
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
        if o in ( '-m', '--mode' ):
            modes = int ( a )
        if o in ( '-s', '--saa' ):
            saa_report = True            
        if o in ( '-p', '--lpa' ):
            lpa_report = True
            lpastates = range(0,4)
#            lpastates = int (a)
        if o in ( '-c', '--lci' ):
            lci_report = True
            lcistates = range(0,4)
#            lcistates = int (a)
        if o in ( '-w', '--pwr' ):
            pwr_report = True
        if o in ( '-a', '--all' ):
            saa_report = True
            mode_report = True
            lpa_report = True
            lci_report = True
        if o in ( '-x', '--exc' ):
            csv = True
        if o in ( '-v', '--verbose' ):
            verbose = True

    for h in uhandlers:
        if h:
            h.setVerbose(verbose)
            h.setModes(modes, mode_report=True)
            h.setSaa(saa_report)
            h.setLpa(lpastates, lpa_report)
            h.setLci(lcistates, lci_report)
            h.setPwr(pwr_report)
            h.setCsv(csv)

    # if a run has been specified, retrieve the start/end times
    # from the database
    if run is not None:
        t0str, t1str = utility.getRunSpan( run, SiteDep.get( 'MakeRetDef',
                                                             'runs_dbi' ) )
        if t0str is None:
            print 'Uptime: run %09d not found' % run
            return 
        print 'Uptime: retrieving data for run %09d %s --> %s' %\
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
    print 'Uptime: populating t&c database from %s' % dbrel
    tlmdb = DecomHlDb( db )
    tlmdb.populate( source=scid, release=dbrel )
    mnems = ['LIMTOPMODE']
    if saa_report: mnems += ['SACFLAGLATINSAA']
    if lpa_report: mnems += ['LIMTLPASTATE']
    if lci_report: mnems += ['LIMTLCISTATE']
    if pwr_report: mnems += ['SE_PAL4_DAQ_INH', 'LPBCBOOTTYPE']
    mnemlist = tlmdb.getMnemList( mnems )
    decom = DecomList( mnemlist, tlmdb=tlmdb )
    
    # set up the decom clients
    for handler in uhandlers:
        if handler: decom.addClient( handler, mnems)

    # retrieve the data for the specified timespan
    try:
        print 'Uptime: creating PktRetriever'
        pktret = PktRetriever( t0ret, t1ret, decom.getAPIDS(), archdir, scid )
        pktret.addClient( decom )
        print 'Uptime: starting packet retrieval'
        pktret.retrievePkts()
    except Exception, e:
        print str(e)
        return 

    uhandlers[2].summarize()

if __name__ == '__main__':
    try:
        Uptime()
    except:
        traceback.print_exc( file=sys.stdout )
        sys.exit( 1 )
        
    
                  
