#!/usr/local/bin/perl
use strict;
use warnings;
use FindBin::libs;

use Perl6::Say;
use Path::Class qw/file/;

use Benchmark qw/:all/;
use Suffix::Array;

my ($file, $q) = @ARGV;

if (not defined $q) {
    die "usage: $0 <file> <query>";
}

my $text = scalar file($file)->slurp;

timethis (
    10, sub {
        my $sa = Suffix::Array->new(\$text);
    }
);

# say for $sa->search_index($q);
