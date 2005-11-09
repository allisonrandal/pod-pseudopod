package Pod::PseudoPod::HTML;
use strict;
use Pod::PseudoPod ();
use vars qw(@ISA $VERSION %tags);
$VERSION = 1.02;
@ISA = ('Pod::PseudoPod');

%tags = (
    'Para' => {
        'start' => '<p>',
        'end'   => '</p>',
    },
    'Verbatim' => {
        'start' => '<pre>',
        'end'   => '</pre>',
    },
    'head0' => {
        'start' => '<h1>',
        'end'   => '</h1>',
    },
    'head1' => {
        'start' => '<h1>',
        'end'   => '</h1>',
    },
    'head2' => {
        'start' => '<h2>',
        'end'   => '</h2>',
    },
    'head3' => {
        'start' => '<h3>',
        'end'   => '</h3>',
    },
    'head4' => {
        'start' => '<h4>',
        'end'   => '</h4>',
    },
    'over_bullet' => {
        'start' => '<ul>',
        'end'   => '</ul>',
    },
);

sub _handle_element_start {
    my ($self,$element,$thirdarg) = @_;

    $element =~ tr/-:./__/;

	my $sub = $self->can( 'start_' . $element );
	$sub->($self,$thirdarg) if $sub; 
}

sub _handle_text {
    my ($self,$text) = @_;

    $self->{'buffer'} .= $text;
}

sub _handle_element_end {
    my ($self,$element,$thirdarg) = @_;

    $element =~ tr/-:./__/;
	my $sub = $self->can( 'start_' . $element );
	$sub->($self) if $sub; 

}

1;


__END__

=head1 NAME

Pod::PseudoPod::Methody -- turn Pod::Simple events into method calls

=head1 SYNOPSIS

 require 5;
 use strict;
 package SomePodFormatter;
 use base qw(Pod::PseudoPod::Methody);
 
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
 
...and start_/end_ methods for whatever other events you want to catch.

=head1 DESCRIPTION

This class is a straight copy of Pod::Simple with the inheritance tree 
twisted a little. I've left the remainder of the documentation untouched 
from the original, but you probably want to look at Pod::Simple::Methody.

This class (which is very small -- read the source) overrides
Pod::Simple's _handle_element_start, _handle_text, and
_handle_element_end methods so that parser events are turned into method
calls. (Otherwise, this is a subclass of L<Pod::Simple> and inherits all
its methods.)

You can use this class as the base class for a Pod formatter/processor.

=head1 METHOD CALLING

When Pod::Simple sees a "=head1 Hi there", for example, it basically does
this:

  $parser->_handle_element_start( "head1", \%attributes );
  $parser->_handle_text( "Hi there" );
  $parser->_handle_element_end( "head1" );

But if you subclass Pod::Simple::Methody, it will instead do this
when it sees a "=head1 Hi there":

  $parser->start_head1( \%attributes ) if $parser->can('start_head1');
  $parser->handle_text( "Hi there" )   if $parser->can('handle_text');
  $parser->end_head1()                 if $parser->can('end_head1');

If Pod::Simple sends an event where the element name has a dash,
period, or colon, the corresponding method name will have a underscore
in its place.  For example, "foo.bar:baz" becomes start_foo_bar_baz
and end_foo_bar_baz.

See the source for Pod::Simple::Text for an example of using this class.

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::Simple::Subclassing>

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2002 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

