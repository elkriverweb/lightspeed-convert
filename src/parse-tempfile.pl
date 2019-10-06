#!/usr/bin/perl
use strict;
use warnings;

use Text::CSV;

my $csv = Text::CSV->new({ binary => 1, sep_char => ',', eol => $/, always_quote => 1 });
my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";

