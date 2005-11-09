# -*- perl -*-

# t/basic.t - check PseudoPod formatting codes and directives

use Test::More qw(no_plan);

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../blib/lib';
    unshift @INC, '../lib';

	use_ok( 'Pod::PseudoPod' );
}

my $object = Pod::PseudoPod->new ();
isa_ok ($object, 'Pod::PseudoPod');

is ($object->{'accept_codes'}->{'F'}, 'F', 'standard formatting codes allowed');

for my $code ('A', 'G', 'H', 'M', 'N', 'R', 'T', 'U') {
    is ($object->{'accept_codes'}->{$code}, $code, "extra formatting code $code allowed");
}

is ($object->{'accept_directives'}->{'head0'}, 'Plain', 'extra directives allowed');
