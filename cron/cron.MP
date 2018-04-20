### usage: 
### (runs on lnxcron.slac.stanford.edu)
### revealed by running command "trscrontab -l" on lnxcron 
### must be in "isocops" environment to run these perl scripts
### which is accomplished by running flightops.sh in the cron job
#
# lnxcron:rac> trscrontab -l
#lnxcron 25 * * * * source /u/gl/glastops/flightops.sh; source /u/gl/rac/cron.SAA
#lnxcron 30 * * * * source /u/gl/glastops/flightops.sh; source /u/gl/rac/cron.MP
#lnxcron 47 * * * * source /u/gl/glastops/flightops.sh; source /u/gl/rac/cron.hourly
#lnxcron 28 2 * * * source /u/gl/glastops/flightops.sh; source /u/gl/rac/cron.nightly
#
# Fermi Mission Planning: 
#
export PERL5LIB=/u/gl/rac/perl5/share/perl5/
PDIR=/u/gl/rac/LATmetrics/planning
$PDIR/filistEphem.pl
#$PDIR/filistSAA.pl
$PDIR/fakeATS.pl -o -p
$PDIR/fakeATS.pl -o
$PDIR/makeATS.pl -o -g -t
$PDIR/makeATS.pl -o
$PDIR/moveMPMWfiles.pl
#
# TDRSS contact schedule updating: 
#
$PDIR/getTDRSS-try.pl > $PDIR/TDRSSschedule.txt
\cp $PDIR/TDRSSschedule.txt /u/gl/rac/public_html/transfer/mics.txt
#$PDIR/getTDRSS-try.pl >| /u/gl/rac/public_html/transfer/mics.txt
