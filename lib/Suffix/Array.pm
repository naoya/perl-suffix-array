package Suffix::Array;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast/;

__PACKAGE__->mk_accessors(qw/text array/);

use List::RubyLike;
use Params::Validate qw/validate_pos ARRAYREF SCALARREF/;
use Perl6::Say;

use constant UCHAR_MAX => 0x100;
use constant EOT       => "\0";

sub new {
    my ($class, $text) = validate_pos(@_, 1, { type => SCALARREF });
    my $self = $class->SUPER::new;

    $self->text = $text;
    $self->array = list;
    $self->_build_sa;

    bless $self, $class;
}

sub _build_sa {
    my $self = shift;

    my @text = unpack('C*', ${$self->text});
    my $len  = @text;
    push @text, ord EOT;

    ## 先頭二文字で2文字分布数えソート
    my @count;
    for (my $i = 0; $i < UCHAR_MAX * UCHAR_MAX; $i++) {
        $count[$i] = 0;
    }

    for (my $i = 0; $i < $len; $i++) {
        $count[ ($text[$i] << 8) + $text[$i + 1] ]++;
    }

    for (my $i = 0; $i < UCHAR_MAX * UCHAR_MAX; $i++) {
        $count[$i + 1] += $count[$i];
    }

    for (my $i = $len - 1; $i >= 0; $i--) {
        $self->array->[ --$count[ ($text[$i] << 8) + $text[$i + 1] ] ] = $i;
    }

    ## [count[i], count[i + 1]) が次のソート区間
    ## (区間幅が 1 の区間はソート済み)
    for (my $i = 0; $i < UCHAR_MAX * UCHAR_MAX - 1; $i++) {
        if ($count[$i + 1] - $count[$i] > 1) {
            radix_sort($self->array, \@text, $count[$i], $count[$i + 1], 2);
        }
    }
}

## [first, last) がソート区間の Suffix Array のインデックス
sub radix_sort {
    my ($array, $base, $first, $last, $pos) = validate_pos(
        @_,
        { type => ARRAYREF },
        { type => ARRAYREF },
        1,
        1,
        1,
    );

    # warn sprintf "zone [%d, %d], pos: $pos", $first, $last, $pos;

    my $width = $last - $first;
    if ($width <= 8) {
       # warn sprintf 'changing to insert-sort ... (width: %d)', $width;
        insert_sort($array, $base, $first, $last, $pos);
        return;
    }

    my @count;
    for (my $i = 0; $i < UCHAR_MAX; $i++) {
        $count[$i] = 0;
    }

    for (my $i = $first; $i < $last; $i++) {
        $count[ $base->[ $array->[$i] + $pos ] ]++;
    }

    for (my $i = 0; $i < UCHAR_MAX; $i++) {
        $count[$i + 1] += $count[$i];
    }

    my @work;
    for (my $i = $last - 1; $i >= $first; $i--) {
        my $c = --$count[ $base->[ $array->[$i] + $pos ] ];
        $work[ $c + $first ] = $array->[$i];
    }

    for (my $i = $first; $i < $last; $i++) {
        $array->[$i] = $work[$i];
    }

    for (my $i = 0; $i < UCHAR_MAX; $i++) {
        my $f = $first + $count[$i];
        my $l = $first + $count[$i + 1];

        if ($l - $f > 1) {
            radix_sort($array, $base, $f, $l, $pos + 1);
        }
    }
}

sub insert_sort {
    my ($array, $base, $first, $last, $pos) = validate_pos(
        @_,
        { type => ARRAYREF },
        { type => ARRAYREF },
        1,
        1,
        1,
    );

    for (my $i = $first + 1; $i < $last; $i++) {
        my $x = $array->[$i];
        my $j = $i - 1;

        ## FIMXE (EOT 置いてるのに...)
        if ($array->[$i] + $pos >= @$base) {
            last;
        }

        if ($array->[$j] + $pos >= @$base) {
            last;
        }

        while ($j >= $first and $base->[$x + $pos] < $base->[$array->[$j] + $pos]) {
            $array->[$j + 1] = $array->[$j];
            $j--;
        }

        $array->[$j + 1] = $x;
    }

    ## FIXME: 入力が長いと stack over flow
    if ($pos < @$base) {
        insert_sort($array, $base, $first, $last, $pos + 1);
    }
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
