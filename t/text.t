# -*- perl -*-

# t/text.t - check output from Pod::PseudoPod::Text

use Test::More qw(no_plan);

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
#$object->parse_file( '../../../../../chapters/ch01.pod' );
$object->filter( '../../../../../chapters/ch01.pod' )->any_errata_seen;
