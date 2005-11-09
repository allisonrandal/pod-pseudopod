# -*- perl -*-

# t/beginend.t - check additions to =begin and =end

use Test::More qw(no_plan);

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../blib/lib';
    unshift @INC, '../lib';

	use_ok( 'Pod::PseudoPod::HTML' );
}

my $results;

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin sidebar

This is the text of the sidebar.

=end sidebar
EOPOD

is($results, <<'EOHTML', "a simple sidebar");
<blockquote>

<p>This is the text of the sidebar.</p>

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

<p>This is the text of the sidebar.</p>

</blockquote>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin sidebar Title Text

This is the text of the Z<strange> sidebar.

=end sidebar
EOPOD

is($results, <<'EOHTML', "a sidebar with a Z<> entity");
<blockquote>
<h3>Title Text</h3>

<p>This is the text of the <a name="strange"> sidebar.</p>

</blockquote>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin programlisting

  This is used for code blocks
  and should have no effect
  beyond ordinary indented text.

=end programlisting
EOPOD

is($results, <<'EOHTML', "allow programlisting blocks");
<pre><code>  This is used for code blocks
  and should have no effect
  beyond ordinary indented text.</code></pre>

EOHTML

initialize($parser, $results);
$parser->add_css_tags(1);
$parser->parse_string_document(<<'EOPOD');
=begin programlisting

  This is used for code blocks
  and should have no effect
  beyond ordinary indented text.

=end programlisting
EOPOD

is($results, <<'EOHTML', "programlising blocks with css tags turned on");
<div class='programlisting'>

<pre><code>  This is used for code blocks
  and should have no effect
  beyond ordinary indented text.</code></pre>

</div>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin blockquote

This is quoted text.

=end blockquote
EOPOD

is($results, <<'EOHTML', "blockquotes");
<p>This is quoted text.</p>

EOHTML


######################################

sub initialize {
	$_[0] = Pod::PseudoPod::HTML->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
