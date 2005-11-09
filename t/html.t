# -*- perl -*-

# t/html.t - check module loading and create testing directory

use Test::More qw(no_plan);

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../blib/lib';
    unshift @INC, '../lib';

	use_ok( 'Pod::PseudoPod::HTML' );
}

my $object = Pod::PseudoPod::HTML->new ();
isa_ok ($object, 'Pod::PseudoPod::HTML');


print "\n";
$object->filter( '../../../../../chapters/ch02.pod' )->any_errata_seen;
