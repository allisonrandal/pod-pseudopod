#!/usr/bin/perl -w

# t/text.t - check output from Pod::PseudoPod::Text

BEGIN {
    chdir 't' if -d 't';
}

use lib '../lib';
use Test::More tests => 5;

use_ok('Pod::PseudoPod::Text') or exit;

my $object = Pod::PseudoPod::Text->new ();
isa_ok ($object, 'Pod::PseudoPod::Text');

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=for text
This is a dummy for block.

EOPOD
is($results, <<"EOTXT", "a simple 'for' block");
    This is a dummy for block.

EOTXT

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin text

This is a dummy begin block.

=end text
EOPOD
is($results, <<"EOTXT", "a simple 'begin' block");
    This is a dummy begin block.

EOTXT
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
