
require 5;
package Pod::PseudoPod::HTML;
use strict;
use Carp ();
use Pod::PseudoPod ();
use vars qw( @ISA $VERSION );
$VERSION = '1.02';
@ISA = ('Pod::PseudoPod');
BEGIN { *DEBUG = defined(&Pod::PseudoPod::DEBUG)
          ? \&Pod::PseudoPod::DEBUG
          : sub() {0}
      }

use Text::Wrap 98.112902 ();
$Text::Wrap::wrap = 'overflow';
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->accept_target_as_text(qw( text plaintext plain ));
#  $new->nix_X_codes(1);
  $new->nbsp_for_S(1);
  $new->{'Thispara'} = '';
  $new->{'Indent'} = 0;
  $new->{'Indentstring'} = '   ';
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_text { $_[0]{'Thispara'} .= $_[1] }

sub start_Para     { $_[0]{'Thispara'} = '<p>' }
sub start_Verbatim { $_[0]{'Thispara'} = '<pre><code>' }

sub start_head0 {  $_[0]{'Thispara'} = '<h1>' }
sub start_head1 {  $_[0]{'Thispara'} = '<h2>' }
sub start_head2 {  $_[0]{'Thispara'} = '<h3>' }
sub start_head3 {  $_[0]{'Thispara'} = '<h4>' }
sub start_head4 {  $_[0]{'Thispara'} = '<h5>' }

sub start_item_bullet { $_[0]{'Thispara'} = '<li>' }
sub start_item_number { $_[0]{'Thispara'} = "<li>$_[1]{'number'}. "  }
sub start_item_text   { $_[0]{'Thispara'} = '<li>'   }

sub start_over_bullet { $_[0]{'Thispara'} = '<ul>'; $_[0]->emit_par() }
sub start_over_text   { $_[0]{'Thispara'} = '<ul>'; $_[0]->emit_par() }
sub start_over_block  { $_[0]{'Thispara'} = '<ul>'; $_[0]->emit_par() }
sub start_over_number { $_[0]{'Thispara'} = '<ol>'; $_[0]->emit_par() }

sub end_over_bullet { $_[0]{'Thispara'} .= '</ul>'; $_[0]->emit_par() }
sub end_over_text   { $_[0]{'Thispara'} .= '</ul>'; $_[0]->emit_par() }
sub end_over_block  { $_[0]{'Thispara'} .= '</ul>'; $_[0]->emit_par() }
sub end_over_number { $_[0]{'Thispara'} .= '</ol>'; $_[0]->emit_par() }

# . . . . . Now the actual formatters:

sub end_Para     { $_[0]{'Thispara'} .= '</p>'; $_[0]->emit_par() }
sub end_Verbatim { $_[0]{'Thispara'} .= '</code></pre>'; $_[0]->emit_par('nowrap') }

sub end_head0       { $_[0]{'Thispara'} .= '</h1>'; $_[0]->emit_par() }
sub end_head1       { $_[0]{'Thispara'} .= '</h2>'; $_[0]->emit_par() }
sub end_head2       { $_[0]{'Thispara'} .= '</h3>'; $_[0]->emit_par() }
sub end_head3       { $_[0]{'Thispara'} .= '</h4>'; $_[0]->emit_par() }
sub end_head4       { $_[0]{'Thispara'} .= '</h5>'; $_[0]->emit_par() }

sub end_item_bullet { $_[0]{'Thispara'} .= '</li>'; $_[0]->emit_par() }
sub end_item_number { $_[0]{'Thispara'} .= '</li>'; $_[0]->emit_par() }
sub end_item_text   { $_[0]->emit_par() }

sub emit_par {
  my($self, $nowrap) = @_;

  my $out = $self->{'Thispara'} . "\n";

  $out = Text::Wrap::wrap('', '', $out) unless $nowrap;

  if(Pod::PseudoPod::ASCII) {
    $out =~ tr{\xA0}{ };
    $out =~ tr{\xAD}{}d;
  }

  print {$self->{'output_fh'}} $out, "\n";
  $self->{'Thispara'} = '';
  
  return;
}

1;

__END__

=head1 NAME

Pod::PseudoPod::HTML -- format PseudoPod as HTML

=head1 SYNOPSIS

  perl -MPod::PseudoPod::HTML -e \
   "exit Pod::PseudoPod::HTML->filter(shift)->any_errata_seen" \
   thingy.pod

=head1 DESCRIPTION

This class is a formatter that takes Pod and renders it as
wrapped html.

Its wrapping is done by L<Text::Wrap>, so you can change
C<$Text::Wrap::columns> as you like.

This is a subclass of L<Pod::PseudoPod> and inherits all its methods.

=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::Simple>

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2003 Allison Randal.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Allison Randal C<allison@cpan.org>

=cut

