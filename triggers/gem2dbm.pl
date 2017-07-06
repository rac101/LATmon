#!/usr/local/bin/perl -w

# 2 simple DBM files contain the GEM counter database
# each DBM file uses "YYYY-MM-DD" as the key/index
# daygem.dbm tracks the GEM counter value for each day.
# gemsod.dbm tracks the seconds-of-day for each day's GEM counter value.

dbmopen(%daygem, "daygem.dbm", 0666);
dbmopen(%gemsod, "gemsod.dbm", 0666);

open(GF, "gem.sent");
while (<GF>) {
    s/:/ /g;
    @f = split;
    $k = $f[0];
    $daygem{$k} = $f[4];
    $gemsod{$k} = $f[1]*3600 + $f[2]*60 + $f[3];
}
