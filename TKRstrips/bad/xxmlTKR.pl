#!/usr/bin/perl -w

# read the XML files containing lists of TKR bad strips

# Robert Cameron
# 2018 March
# 
# usage: 
# ./xxmlTKR.pl XML/LAT_BadStrips_NN.xml > NN.sum 2>> summary

# example relevant lines from the XML file: 
#  <tower row="3" col="3" hwserial="TkrFM11" >
#    <!-- Layer X0 -->
#    <uniplane tray="1" which="bot" >
#      <stripList strips= "157 276 690 810 849 853 854 855 863 967 1481 " />
#    </uniplane>  <!-- nStrips: 11 -->

@f = split ("/",$ARGV[0]);
@inp = `cat $ARGV[0]`;

$total = 0;
$summary = $f[-1];
$ttotal = '';
print "$summary\n\n";

foreach (@inp) {
    if (/<tower row=/) {
	print "$fm\tTKR: $tkr  Row: $row  Col: $col Planes: $ltotal   Strips = $ttotal\n\n" if ($total);
	$summary .= " $ttotal";
	/<tower row="(\d+)" col="(\d+)" hwserial="(\w+)"/;
	$row = $1;
	$col = $2;
	$tkr = $row*4 + $col;
	$fm = $3;
	$ttotal = 0;
	$ltotal = 0;
    }
    if (/<!-- Layer /) {
	/<!-- Layer (\w+) -->/;
	$layer = layerid($1);
	$ltotal++;
    }
    if (/<\/uniplane>  <!-- nStrips: /) {
	/<\/uniplane>  <!-- nStrips: (\d+) -->/;
	$total += $1;
	$ttotal += $1;
	print "\tTKR: $tkr\tLayer: $layer\tScount = $1\n";
    }
}
print "$fm\tTKR: $tkr  Row: $row  Col: $col Planes: $ltotal   Strips = $ttotal\n\n";
$summary .= " $ttotal";
print "$summary     $total\n";

sub layerid {

    $l = shift;
    $l =~ /(\D)(\d+)/;
    $xy = $1;
    $num2 = $2 * 2;
    $num2++ if ( ($2 % 2) and $xy eq "Y"); 
    $num2++ if (!($2 % 2) and $xy eq "X"); 
    return "$l = $num2";
}
