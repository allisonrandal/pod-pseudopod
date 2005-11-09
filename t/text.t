# -*- perl -*-

# t/text.t - check module loading and create testing directory

use Test::More tests => 5;

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../blib/lib';
    unshift @INC, '../lib';

	use_ok( 'Pod::PseudoPod::Text' );
}

my $object = Pod::PseudoPod::Text->new ();
isa_ok ($object, 'Pod::PseudoPod::Text');

#is ($object->{'accept_codes'}->{'F'}, 'F', 'standard formatting codes allowed');
#is ($object->{'accept_codes'}->{'U'}, 'U', 'extra formatting codes allowed');
#is ($object->{'accept_directives'}->{'head0'}, 'Plain', 'extra directives allowed');

print "\n";
#$object->output_fh( *STDOUT );
#$object->parse_file( '/home/allison/projects/perforce/books/p6e/ch01.pod' );
$object->filter( '/home/allison/projects/perforce/books/p6e/ch01.pod' )->any_errata_seen;
