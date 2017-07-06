#!/usr/local/bin/perl -w

# merge missed memory error data into the archive file

#Usage: > ./archmerge.pl < missed_data_file > STDOUT

#input format
#EPU1: 2012-04-22 18:21:41.784301 (1335118901.784301)  Address:   62151696 (0x03b45c10)  Type: 4 (Correctable multi-bit error) -25.944944 -23.729332 1
#EPU0: 2012-04-22 18:21:50.934978 (1335118910.934978)  Address:   99947224 (0x05f512d8)  Type: 3 (Correctable single-bit error) -25.376673 -23.628370 1
# SIU: 2012-04-22 20:02:09.423836 (1335124929.423836)  Address:  131599768 (0x07d80d98)  Type: 4 (Correctable multi-bit error) -31.731960 -19.124795 1
#EPU1: 2012-04-22 21:46:49.660921 (1335131209.660921)  Address:   94636400 (0x05a40970)  Type: 3 (Correctable single-bit error) -25.210983 -6.104414 1

#@doy = ([0,0,31,59,90,120,151,181,212,243,273,304,334],[0,0,31,60,91,121,152,182,213,244,274,305,335]);
#@dom = (-163);    # linear Day Of Mission 
#foreach (1..99) {
#    $n = 365;
#    if (($_ % 4) == 1) { $n = 366 };
#    push @dom,$dom[$_-1]+$n;
#}

open (AF,'geosaa.out') or die "$0: Cannot open archive data file\n";
while (<AF>) {
    next unless (/U/);
    @f = split; 
    push @{$hoa{$f[1]}},$_;
}

while (<>) {
    next unless (/U/);
    @f = split; 
    push @{$hoa{$f[1]}},$_;
}

@k = sort { $a cmp $b } keys(%hoa); 

foreach $day (@k) {
    print @{$hoa{$day}},"\n";
#    foreach $memerr (@{hoa{$day}})
}
