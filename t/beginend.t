# -*- perl -*-

# t/beginend.t - check additions to =begin and =end

use Test::More qw(no_plan);

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../blib/lib';
    unshift @INC, '../lib';

	use_ok( 'Pod::PseudoPod::HTML' );
}

my $parser = Pod::PseudoPod::HTML->new ();
isa_ok ($parser, 'Pod::PseudoPod::HTML');

my $results;

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin sidebar

This is the text of the sidebar.

=end sidebar
EOPOD

is($results, <<'EOHTML', "a simple sidebar");
<blockquote>
This is the text of the sidebar.
</blockquote>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin sidebar Title Text

This is the text of the sidebar.

=end sidebar
EOPOD

is($results, <<'EOHTML', "a sidebar with a title");
<blockquote>
<h3>Title Text</h3>
This is the text of the sidebar.
</blockquote>

EOHTML

TODO: {
local $TODO = "need to process as text without killing begin_for event";
initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin sidebar Title Text

This is the text of the Z<strange> sidebar.

=end sidebar
EOPOD

is($results, <<'EOHTML', "a sidebar with a Z<> entity");
<blockquote>
<h3>Title Text</h3>
This is the text of the <a name="strange"> sidebar.
</blockquote>

EOHTML
};

######################################

sub initialize {
	$_[0] = Pod::PseudoPod::HTML->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
