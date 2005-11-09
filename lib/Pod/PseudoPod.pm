
package Pod::PseudoPod;
use Pod::Simple;
@ISA = qw(Pod::Simple);
use strict;

use vars qw(
  $VERSION @ISA
  @Known_formatting_codes  @Known_directives
  %Known_formatting_codes  %Known_directives
);

@ISA = ('Pod::Simple');
$VERSION = '0.01';

@Known_formatting_codes = qw(A B C E F I L M N R S T U X Z _ ^);
%Known_formatting_codes = map(($_=>1), @Known_formatting_codes);
@Known_directives       = qw(head0 head1 head2 head3 head4 item over back);
%Known_directives       = map(($_=>'Plain'), @Known_directives);

sub new {
  my $self = shift;
  my $new = $self->SUPER::new();

  $new->{'accept_codes'} = { map( ($_=>$_), @Known_formatting_codes ) };
  $new->{'accept_directives'} = \%Known_directives;
  return $new;
}

sub _handle_element_start {
  my ($self, $element, $arg) = @_;

  $element =~ tr/-:./__/;

  my $sub = $self->can('start_' . $element);
  $sub->($self,$arg) if $sub; 
}

sub _handle_text {
  my $self = shift;

  my $sub = $self->can('handle_text');
  $sub->($self, @_) if $sub;
}

sub _handle_element_end {
  my ($self,$element) = @_;
  $element =~ tr/-:./__/;

  my $sub = $self->can('end_' . $element);
  $sub->($self) if $sub;
}

1; 

__END__

=head1 NAME

Pod::PseudoPod - A framework for parsing PseudoPOD

=head1 SYNOPSIS

  use strict;
  package SomePseudoPodFormatter;
  use base qw(Pod::PseudoPod);

  sub handle_text {
    my($self, $text) = @_;
    ...
  }

  sub start_head1 {
    my($self, $attrs) = @_;
    ...
  }
  sub end_head1 {
    my($self) = @_;
   ...
  }

  ...and start_*/end_* methods for whatever other events you
  want to catch.


=head1 DESCRIPTION

PseudoPOD is O'Reilly's extended set of POD tags for book manuscripts.
Standard POD doesn't have all the markup options you might want for
marking up files for publishing production. PseudoPOD adds a few extra
tags for footnotes, etc.

This class adds parsing support for the PseudoPOD tags. It also
overrides Pod::Simple's C<_handle_element_start>, C<_handle_text>, and
C<_handle_element_end> methods so that parser events are turned into
method calls. (Otherwise, this is a subclass of Pod::Simple and
inherits all its methods.)

You can use this class as the base class for a PseudoPod
formatter/processor.

=head1 SEE ALSO

L<Pod::Simple>

=head1 COPYRIGHT

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

