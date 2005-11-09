# -*- perl -*-

# t/html.t - check module loading and create testing directory

use Test::More tests => 5;

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../blib/lib';
    unshift @INC, '../lib';

	use_ok( 'Pod::PseudoPod::HTML' );
}

my $object = Pod::PseudoPod::HTML->new ();
isa_ok ($object, 'Pod::PseudoPod::HTML');


print "\n";
$object->filter( '/home/allison/projects/perforce/books/p6e/ch02.pod' )->any_errata_seen;
