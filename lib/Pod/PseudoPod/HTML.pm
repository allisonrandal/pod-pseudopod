
require 5;
package Pod::PseudoPod::HTML;
use strict;
use Carp ();
use vars qw( $VERSION );
$VERSION = '0.02';
use base qw( Pod::PseudoPod );

use Text::Wrap 98.112902 ();
$Text::Wrap::wrap = 'overflow';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->accept_target_as_text(qw( text plaintext plain ));
  $new->nix_X_codes(1);
  $new->nbsp_for_S(1);
  $new->{'scratch'} = '';
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_text { $_[0]{'scratch'} .= $_[1] }

sub start_Para     { $_[0]{'scratch'} = '<p>' }
sub start_Verbatim { $_[0]{'scratch'} = '<pre><code>' }

sub start_head0 {  $_[0]{'scratch'} = '<h1>' }
sub start_head1 {  $_[0]{'scratch'} = '<h2>' }
sub start_head2 {  $_[0]{'scratch'} = '<h3>' }
sub start_head3 {  $_[0]{'scratch'} = '<h4>' }
sub start_head4 {  $_[0]{'scratch'} = '<h5>' }

sub start_item_bullet { $_[0]{'scratch'} = '<li>' }
sub start_item_number { $_[0]{'scratch'} = "<li>$_[1]{'number'}. "  }
sub start_item_text   { $_[0]{'scratch'} = '<li>'   }

sub start_over_bullet { $_[0]{'scratch'} = '<ul>'; $_[0]->emit() }
sub start_over_text   { $_[0]{'scratch'} = '<ul>'; $_[0]->emit() }
sub start_over_block  { $_[0]{'scratch'} = '<ul>'; $_[0]->emit() }
sub start_over_number { $_[0]{'scratch'} = '<ol>'; $_[0]->emit() }

sub end_over_bullet { $_[0]{'scratch'} .= '</ul>'; $_[0]->emit() }
sub end_over_text   { $_[0]{'scratch'} .= '</ul>'; $_[0]->emit() }
sub end_over_block  { $_[0]{'scratch'} .= '</ul>'; $_[0]->emit() }
sub end_over_number { $_[0]{'scratch'} .= '</ol>'; $_[0]->emit() }

# . . . . . Now the actual formatters:

sub end_Para     { $_[0]{'scratch'} .= '</p>'; $_[0]->emit() }
sub end_Verbatim { $_[0]{'scratch'} .= '</code></pre>'; $_[0]->emit('nowrap') }

sub end_head0       { $_[0]{'scratch'} .= '</h1>'; $_[0]->emit() }
sub end_head1       { $_[0]{'scratch'} .= '</h2>'; $_[0]->emit() }
sub end_head2       { $_[0]{'scratch'} .= '</h3>'; $_[0]->emit() }
sub end_head3       { $_[0]{'scratch'} .= '</h4>'; $_[0]->emit() }
sub end_head4       { $_[0]{'scratch'} .= '</h5>'; $_[0]->emit() }

sub end_item_bullet { $_[0]{'scratch'} .= '</li>'; $_[0]->emit() }
sub end_item_number { $_[0]{'scratch'} .= '</li>'; $_[0]->emit() }
sub end_item_text   { $_[0]->emit() }

# Handling code tags
sub start_C { $_[0]{'scratch'} .= '<code>' }
sub end_C   { $_[0]{'scratch'} .= '</code>' }

sub start_N { $_[0]{'scratch'} .= ' (footnote: ' }
sub end_N   { $_[0]{'scratch'} .= ')' }

sub emit {
  my($self, $nowrap) = @_;

  my $out = $self->{'scratch'} . "\n";

  $out = Text::Wrap::wrap('', '', $out) unless $nowrap;

  if(Pod::PseudoPod::ASCII) {
    $out =~ tr{\xA0}{ };
    $out =~ tr{\xAD}{}d;
  }

  print {$self->{'output_fh'}} $out, "\n";
  $self->{'scratch'} = '';
  
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

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Allison Randal C<allison@cpan.org>

=cut
