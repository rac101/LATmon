#!/usr/local/bin/perl

# analyse and summarize daily uptime numbers collected using Jana's Uptime.py script

# Robert Cameron
# May 2012

# usage: ./atup.pl

#t0 t1 Total TERMINAL QUIESCENT CALIBRATION DIAGNOSTIC PHYSICS PHYSICS_SAA TOO TOO_SAA ARR ARR_SAA HOLD BOOT OFF SAA IDLE RUNNING STOPPING UNKNOWN IDLE RUNNING STOPPING UNKNOWN 
#                                                                    LIM Mode Summary-----------------'
# 2008-07-30 23:59:55.340094 2008-08-01 00:00:04.340101 86408.000006 89.323223 19990.811864 0 0 41980.099320 0 0 0 180.540356 0 0 0 0 34375.260756 20342.698928 41959.864189 20.233290 0 62322.800066 0 0 0 
# 2008-07-31 23:59:55.340101 2008-08-02 00:00:04.340073 86407.999970 0 0 0 0 0 0 0 0 0 0 0 0 0 86407.999970 0 0 0 0 0 0 0 0 

open( TUP, "tup.out" ) or die "$0: Cannot open input file 'tup.out'\n";
while (<TUP>) {
    next unless /20/;
    next if /2008-07/;
    ($t00,$t01,$t10,$t11,$tot,$ter,$qui,$cal,$dia,$phy,$phy_sa,$too,$too_sa,$arr,$arr_sa,$hol,$boo,$off,$saa,$lp_id,$lp_ru,$lp_st,$lp_un,$lc_id,$lc_ru,$lc_st,$lc_un) = split;
    print "$t00 $t01: total time is small: int($tot)\n" if ($tot < 86401);
    print "$t00 $t01: non-zero Off time found: $off\n" if ($off);
    print "$t00 $t01: LAT might be off or safed due to large SAA time: $saa\n" if ($saa > 18000);
    print "$t00 $t01: LAT might be off or safed due to small Physics time: $phy\n" if ($phy < 58000);
}
