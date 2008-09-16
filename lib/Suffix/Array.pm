package Suffix::Array;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast/;

__PACKAGE__->mk_accessors(qw/text array/);

use List::RubyLike;
use Params::Validate qw/validate_pos/;

sub new {
    my ($class, $text) = validate_pos(@_, 1, 1);
    my $self = $class->SUPER::new;

    $self->text  = \$text;
    $self->array = list;
    $self->_init;
    $self->_build_sa;

    bless $self, $class;
}

sub _init {
    my $self = shift;
    my $len = length ${$self->text};
    for (0..$len-1) {
        $self->array->[$_] = $_;
    }
}

sub _build_sa {
    my $self = shift;

    ## TODO1: ソートアルゴリズムを Ko and Aluru '03 など Suffix Array 専用のものに変更
    ## TODO2: Sorter を変更できるようにする?
    my $by_suffix = sub {
        my ($a, $b) = @_;
        substr(${$self->text}, $a) cmp substr(${$self->text}, $b);
    };

    $self->array = $self->array->sort($by_suffix);
}

sub search_index {
    my ($self, $q) = validate_pos(@_, 1, 1);
    my $pos = $self->bsearch($q, -1, $self->array->size) or return;

    my @ret;
    while ($q eq substr(${$self->text}, $self->array->[$pos], length $q)) {
        push @ret, $pos;
        $pos++;

        if (not defined $self->array->[$pos]) {
            last;
        }
    }

    return @ret;
}

sub bsearch {
    my ($self, $q, $start, $end) = validate_pos(@_, 1 , 1, 1, 1);

    if ($start+1 == $end) {
        return $end;
    }

    my $pos = int(($start + $end) / 2);
    my $str = substr(${$self->text}, $self->array->[$pos], length $q);

    (($q cmp $str) > 0)
        ? $self->bsearch($q, $pos, $end)
        : $self->bsearch($q, $start, $pos);
}

sub show {
    my $self = shift;
    my $len = $self->array->size;

    $self->array->each_index(sub {
        printf
            "sa[%2d] = %2d, substr(text, %2d) = %s\n",
            $_,
            $self->array->[$_],
            $self->array->[$_],
            substr(${$self->text}, $self->array->[$_]),
        ;
    });
}

1;
