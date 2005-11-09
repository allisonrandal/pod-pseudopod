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


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a link anchorZ<crossreferenceendpoint>.
EOPOD
is($results, <<"EOTXT", "Link anchor entity in a paragraph");
    A plain paragraph with a link anchor.

EOTXT

######################################

sub initialize {
	$_[0] = Pod::PseudoPod::Text->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
