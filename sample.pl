#!/usr/local/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Perl6::Say;

use Suffix::Array;

my ($text, $q) = @ARGV;

if (not defined $q) {
    die "usage: $0 <text> <query>";
}

my $sa = Suffix::Array->new(\$text);
$sa->show;

say for $sa->search_index($q);
