package Bencher::Formatter::ScaleTime;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use List::MoreUtils qw(minmax);
use POSIX ();

use Role::Tiny::With;
with 'Bencher::Role::ResultMunger';

sub munge_result {
    my ($self, $envres) = @_;

    # pick an appropriate time unit & format the time
    my ($min, $max) = minmax(map {$_->{time}} @{$envres->[2]});

    my ($unit, $factor);
    if ($max <= 1.5e-6) {
        $unit = "ns";
        $factor = 1e9;
    } elsif ($max <= 1.5e-3) {
        $unit = "\x{03bc}s"; # XXX enable utf
        $factor = 1e6;
    } elsif ($max <= 1.5) {
        $unit = "ms";
        $factor = 1e3;
    }

    if ($unit) {
        for my $rit (@{$envres->[2]}) {
            $rit->{time} *= $factor;
            if (exists $rit->{mod_overhead_time}) {
                $rit->{mod_overhead_time} *= $factor;
            }
        }

        $envres->[3]{'table.field_units'} //= [];
        my $fus = $envres->[3]{'table.field_units'};

        my $i = -1;
        for my $f (@{$envres->[3]{'table.fields'}}) {
            $i++;
            if ($f =~ /\A(time|mod_overhead_time)\z/) {
                $fus->[$i] = $unit;
            }
        }
    }
}

1;
# ABSTRACT: Scale time to make it convenient

=for Pod::Coverage .*