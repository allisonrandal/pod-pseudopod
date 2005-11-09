
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

1; 

__END__

=head1 NAME

Pod::PseudoPod - A framework for parsing PseudoPOD

=head1 SYNOPSIS

  use Pod::PseudoPod
  blah blah blah


=head1 DESCRIPTION

PseudoPOD is O'Reilly's extended set of POD tags for book manuscripts. Standard
POD doesn't have all the markup options you might want for marking up files for
publishing production. PseudoPOD adds a few extra tags for footnotes, etc.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

	Allison Randal <al@shadowed.net>
	http://www.onyxneon.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comments  : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   : 

=cut

################################################## subroutine header end ##




