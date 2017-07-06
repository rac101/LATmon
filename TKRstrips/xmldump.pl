#!/usr/local/bin/perl -w

# A very simple XML inspection script
# Robert Cameron
# 2011 May 12
# 
# call this script with the XML filename as the first command argument

# use modules
use XML::Simple;
use Data::Dumper;

# create object
$xml = new XML::Simple;

# read XML file
$d = $xml->XMLin($ARGV[0]);

# print output
# print Dumper($d);

#@t = $d->{tower};
#print $#t,"\n";
#foreach $ti (0..$#t) {
#    print "$ti\n";
#    $th = $t[$ti];
#    @p = $th->{uniplane};
#    foreach $pi (0..$#p) {
#       $ph = $p[$pi];
#       if ($ph->{stripList}) { print "$ti $pi ",$ph->{stripList}{strips},"\n" }
#    }
#}

$n = 0;
foreach $ti (0..15) {
    $t = ${$d->{tower}}[$ti];
    $c = 0;
    foreach $pi (0..35) {
        $p = ${$t->{uniplane}}[35-$pi];
        if ($p->{stripList}) { 
            $l = split ' ',$p->{stripList}{strips};
            print "T$ti L$pi = $l: ",$p->{stripList}{strips},"\n";
            $c += $l;
        }
    }
    print "Tower $ti: $c\n";
    $n += $c;
}
print "Total = $n\n";

#foreach $ti (@{$d->{tower}}) {
#    $th = ${$d->{tower}}[$$ti];
#    foreach $pi (@{$th->{uniplane}}) {
#       $ph = ${$data->{uniplane}}[$$pi];
#       if ($ph->{stripList}) { print "$$ti $$pi ",$ph->{stripList}{strips},"\n" }
#    }
#}

# ok x $data->{tower}
# ok @t = $data->{tower}
# ok foreach $t (@{$data->{tower}})
# ok x ${$data->{tower}}[0]
# notok x ${${$data->{tower}}[0]}->{tray}
# Not a SCALAR reference at (eval 52)[/opt/local/lib/perl5/5.8.9/perl5db.pl:638] line 2.
# ok $q = ${$data->{tower}}[0]
# ok x $q->{uniplane}
# notok x $q{uniplane}
# notok $u = $q->{uniplane}
# Can't modify single ref constructor in scalar assignment at (eval 57)[/opt/local/lib/perl5/5.8.9/perl5db.pl:638] line 2, at EOF
# ok x ${$q->{uniplane}}[1]
# ok $a = ${$q->{uniplane}}[23]
# ok x $a
# notok x $a->{strips}
# ok x $a->{stripList}
# ok x $a->{stripList}{strips}
