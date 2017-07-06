#!/usr/local/bin/perl -w

# print in colors, bold and underline to the terminal.

use Term::ANSIColor;


print color 'bold blue';
print "This text is bold blue.\n";
print color 'reset';
print "This text is normal.\n";
print colored("Yellow on magenta.", 'yellow on_magenta'), "\n";
print "This text is normal.\n";
print colored ['bold yellow on_magenta'], 'Bold yellow on magenta.', "\n";
print colored ['red on_yellow'], 'Red on yellow.', "\n";
print colored ['bold red on_yellow'], 'Bold Red on yellow.', "\n";
print colored ['bold red on_black'], 'Bold red on black.', "\n";
print colored ['bold green on_red'], 'Bold green on red.', "\n\n";
print "This text is normal.\n";
print colored ("this is green underlined", 'green underline'), "\n";
print colored ("this is green", 'green'), "\n";
print colored ("this is bold green", 'bold green'), "\n";
print colored ("this is cyan", 'cyan');
print colored (" and this is bold cyan", 'bold cyan'), "\n";
print colored (" and this is blue", 'blue'), "\n";"\n";
print colored (" bold but otherwise normal", 'bold'), "\n";
print colored ("normal bold underlined", 'bold underline'), " and finally back to normal\n";
print "\n";
