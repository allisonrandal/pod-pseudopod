package Pod::PseudoPod::DocBook;
use strict;
use vars qw( $VERSION );
$VERSION = '0.12';
use Carp ();
use base qw( Pod::PseudoPod );

use HTML::Entities 'encode_entities';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->accept_targets( 'docbook', 'DocBook' );
  $new->accept_targets_as_text( qw(author blockquote caution
      editor epigraph example figure important literal note
      production screen sidebar table tip warning) );

  $new->nix_Z_codes(1);
  $new->nbsp_for_S(1);
  $new->codes_in_verbatim(1);
  $new->chapter_type('chapter'); # default chapter type
  $new->{'scratch'} = '';
  $new->{'sections'} = (); # a stack for tracking section nesting
  $new->{'sectionnum'} = (); # a list for tracking section number
  $new->{'sectionname'} = ['chapter','sect1', 'sect2', 'sect3', 'sect4'];
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#sub handle_text {
    # escape special characters in DocBook (<, >, &, etc)
#    $_[0]{'scratch'} .= $_[0]{'in_verbatim'} ? encode_entities( $_[1] ) : $_[1]
#}

sub handle_text {
    # escape special characters in DocBook (<, >, &, etc)
    $_[0]{'scratch'} .= encode_entities( $_[1] );
}

sub start_Para     { $_[0]{'scratch'} = '<para>' unless $_[0]{'in_figure'} }
sub start_Verbatim {
  $_[0]{'scratch'} = "<programlisting>\n" unless ($_[0]{'in_screen'});
  $_[0]{'in_verbatim'} = 1;
}

sub start_head0 { $_[0]->set_section(0); }
sub start_head1 { $_[0]->set_section(1); }
sub start_head2 { $_[0]->set_section(2); }
sub start_head3 { $_[0]->set_section(3); }
sub start_head4 { $_[0]->set_section(4); }

sub set_section {
    my ($self, $level) = @_;
    $self->{'scratch'} = $self->close_sections($level);
    $self->{'sectionnum'}[$level]++ if ($level > 0);
    my $label = join '.', @{$self->{'sectionnum'}};
    my $id = $self->chapter_id();
    if ($level > 0) {
      $id .= '-SECT-';
      my @sectionnum = @{$self->{'sectionnum'}};
      $id .= join '.', @sectionnum[1 ..  $#sectionnum];
    }
    $self->{'scratch'} .= '<' . $self->{'sectionname'}[$level];
    $self->{'scratch'} .= ' id="' . $id;
    $self->{'scratch'} .= '" label="' . $label unless $self->{'chapter_type'} eq 'preface';
    $self->{'scratch'} .= '" role="">';
    $self->{'scratch'} .= "\n<title>";
    push @{$self->{'sections'}}, $level;
}

sub close_sections {
    my ($self, $level) = @_;
    my $scratch = '';
    my $sections = $self->{'sections'};
    # Are we starting a new section that isn't a subsection?
    while  (defined $sections
            && @$sections > 0
            && $level <= $sections->[-1]) {
        my $closing = pop @$sections;
        delete $self->{'sectionnum'}[$closing + 1];
        $scratch .= "</" . $self->{'sectionname'}[$closing] . ">\n";
    }
    return $scratch;
}

sub start_over_bullet { $_[0]{'scratch'} = '<itemizedlist>'; $_[0]->emit() }
sub start_over_block  { $_[0]{'scratch'} = '<itemizedlist>'; $_[0]->emit() }
sub start_over_number { $_[0]{'scratch'} = '<orderedlist>'; $_[0]->emit() }
sub start_over_text   { $_[0]{'scratch'} = '<variablelist>'; $_[0]->emit() }

sub end_over_bullet { $_[0]{'scratch'} .= '</itemizedlist>'; $_[0]->emit() }
sub end_over_block  { $_[0]{'scratch'} .= '</itemizedlist>'; $_[0]->emit() }
sub end_over_number {
  $_[0]{'scratch'} .= "</para></listitem>\n" if ($_[0]{'in_numlist'});
  $_[0]{'scratch'} .= '</orderedlist>';
  $_[0]{'in_numlist'} = 0;
  $_[0]->emit();
}
sub end_over_text   { 
  $_[0]{'scratch'} .= "</listitem>\n</varlistentry>\n" if ($_[0]{'in_varlist'});
  $_[0]{'scratch'} .= '</variablelist>';
  $_[0]{'in_varlist'} = 0;
  $_[0]->emit();
}

sub start_item_bullet { $_[0]{'scratch'} = '<listitem><para>' }
sub end_item_bullet { $_[0]{'scratch'} .= '</para></listitem>'; $_[0]->emit() }

sub start_item_number { 
  $_[0]{'scratch'} .= "</para></listitem>\n" if ($_[0]{'in_numlist'});
  $_[0]{'scratch'} .= "<listitem><para>";
  $_[0]{'in_numlist'} = 1;
}
sub end_item_number {
  $_[0]->emit()
}

sub start_item_text   { 
    $_[0]{'scratch'} .= "</listitem>\n</varlistentry>\n" if ($_[0]{'in_varlist'});
    $_[0]{'scratch'} .= "<varlistentry>\n<term>"; 
    $_[0]{'in_varlist'} = 1; 
}

sub end_item_text { 
    $_[0]{'scratch'} .= "</term>\n<listitem>";
    $_[0]->emit() 
 }


# . . . . . Now the actual formatters:

sub end_Para {
    unless ($_[0]{'in_figure'}) { 
        $_[0]{'scratch'} .= '</para>';
        $_[0]->emit();
    }
}
sub end_Verbatim {
    $_[0]{'scratch'}     .= "\n</programlisting>" unless ($_[0]{'in_screen'});
    $_[0]{'in_verbatim'}  = 0;
    $_[0]->emit();
}

sub end_head0       { $_[0]{'scratch'} .= '</title>'; $_[0]->emit() }
sub end_head1       { $_[0]{'scratch'} .= '</title>'; $_[0]->emit() }
sub end_head2       { $_[0]{'scratch'} .= '</title>'; $_[0]->emit() }
sub end_head3       { $_[0]{'scratch'} .= '</title>'; $_[0]->emit() }
sub end_head4       { $_[0]{'scratch'} .= '</title>'; $_[0]->emit() }


sub start_sidebar { 
  my ($self, $flags) = @_;
  $self->{'scratch'} = '<sidebar>';
  if ($flags->{'title'}) {
    $self->{'scratch'} .= "\n<title>" . $flags->{'title'} . "</title>";
  }
  $self->emit();
}

sub end_sidebar { $_[0]{'scratch'} .= '</sidebar>'; $_[0]->emit() }

sub start_figure { 
  my ($self, $flags)      = @_;
  $self->{'in_figure'}    = 1;
  $self->{'scratch'} .= '<figure>';
  $self->{'scratch'} .= '<title>' . $flags->{'title'} .  '</title>' if $flags->{'title'};
  $self->{'scratch'} .= '<mediaobject><imageobject role="print">';
}

sub end_figure { 
  my ($self, $flags)   = @_;
  $self->{'in_figure'} = 0;

  $self->{'scratch'} .= "</imageobject></mediaobject>\n";
  $self->{'scratch'} .= "</figure>";

  $self->emit();
}

# This handles =begin and =for blocks of all kinds.
sub start_for { 
    my ($self, $flags) = @_;
    my $target = $flags->{'target'};
    $self->{'scratch'} .= "<$target>";
    $self->{"in_$target"} = 1;
    $self->emit();

}
sub end_for { 
    my ($self, $flags) = @_;
    my $target = $flags->{'target'};
    $self->{'scratch'} .= "</$target>";
    $self->{"in_$target"} = 0;
    $self->emit();
}

sub start_table { 
  my ($self, $flags) = @_;
  my $id = $self->chapter_id() . '-TABLE-'. $self->table_next();
  $self->{'scratch'} .= '<table id="'.$id.'" label="" frame="topbot" ';
  $self->{'scratch'} .= 'colsep="0" rowsep="0">';
  if ($flags->{'title'}) {
    $self->{'scratch'} .= "\n<title>" . $flags->{'title'} . '</title>';
  }
  $self->{'scratch'} .= "\n" . '<tgroup cols="">';
  $self->emit();
}
sub table_next { ++$_[0]{'table_count'} }

sub end_table   { $_[0]{'scratch'} .= '</tbody></tgroup></table>'; $_[0]->emit() }

sub start_headrow { $_[0]{'scratch'} .= "<thead>\n"; $_[0]{'headrow'} = 1 }
sub start_bodyrows {
    my ($self, $flags) = @_;
    $self->{'scratch'} .= "</thead>\n" if ($self->{'headrow'});
    $self->{'headrow'} = 0;
    $self->{'scratch'} .= "<tbody>\n";
}

sub start_row {$_[0]{'scratch'} .= "<row>\n" }
sub end_row { $_[0]{'scratch'} .= '</row>'; $_[0]->emit() }

sub start_cell {
  $_[0]{'scratch'} .= '<entry align="left"><para>';
}
sub end_cell { 
  my $self = shift;
  $self->{'scratch'} .= '</para></entry>';
  $self->emit();
}

sub start_Document { 
    my ($self) = @_;
}
sub end_Document   { 
    my ($self) = @_;
    $self->{'scratch'} .= $self->close_sections(-1);
    $self->emit();
}

# Handling entity tags
sub start_A { $_[0]{'scratch'} .= '<link linkend="#' }
sub end_A   { $_[0]{'scratch'} .= '">link</link>' }

sub start_B { $_[0]{'scratch'} .= '<emphasis role="strong">' }
sub end_B   { $_[0]{'scratch'} .= '</emphasis>' }

sub start_C { $_[0]{'scratch'} .= '<literal>' }
sub end_C   { $_[0]{'scratch'} .= '</literal>' }

sub start_E { $_[0]{'scratch'} .= '&' }
sub end_E   { $_[0]{'scratch'} .= ';' }

sub start_F { $_[0]{'scratch'} .= ($_[0]{'in_figure'}) ? '<imagedata fileref="' : '<filename>' }
sub end_F   { $_[0]{'scratch'} .= ($_[0]{'in_figure'}) ? '"/>' : '</filename>' }

sub start_G { $_[0]{'scratch'} .= '<superscript>' }
sub end_G   { $_[0]{'scratch'} .= '</superscript>' }

sub start_H { $_[0]{'scratch'} .= '<subscript>' }
sub end_H   { $_[0]{'scratch'} .= '</subscript>' }

sub start_I { $_[0]{'scratch'} .= '<emphasis>' }
sub end_I   { $_[0]{'scratch'} .= '</emphasis>' }

sub start_N {
  my ($self) = @_;
  my $id = $self->chapter_id() . '-FNOTE-'. $self->footnote_next();
  $self->{'scratch'} .= '<footnote id="'.$id.'" label="*"><para>';
}
sub end_N {
  my ($self) = @_;
  $self->{'scratch'} .= '</para></footnote>';
}
sub footnote_next { ++$_[0]{'footnote_count'} }

sub start_R { $_[0]{'scratch'} .= '<replaceable>' }
sub end_R   { $_[0]{'scratch'} .= '</replaceable>' }

sub start_U { $_[0]{'scratch'} .= '<systemitem role="url">' }
sub end_U   { $_[0]{'scratch'} .= '</systemitem>' }

sub start_X {
  my ($self) = @_;
  my $id = $self->chapter_id() . '-IDX-' . $self->index_next();
  $self->{'scratch'} .= '<indexterm id="'.$id.'"><primary>';
}
sub end_X   { $_[0]{'scratch'} .= '</primary></indexterm>' }
sub index_next { 
  my ($self) = @_;
  my $idx = ++$self->{'index_count'}; 
  return sprintf("%04d", $idx);
}

sub emit {
  my($self) = @_;
  if ($self->{'scratch'}) {
      my $out = $self->{'scratch'} . "\n";
      print {$self->{'output_fh'}} $out;
      $self->{'scratch'} = '';
  }
  return;
}

sub book_id { $_[0]{'book_id'} = $_[1] }
sub index_count {
  $_[0]{'index_count'} = $_[1] if ($_[1]);
  return $_[0]{'index_count'};
}
sub chapter_num { 
    my ($self, $number) = @_;
    $self->{'chapter_num'} = $number;
    $self->{'sectionnum'}[0] = $number;
}
sub chapter_type { 
    my ($self, $type) = @_;
    $self->{'chapter_type'} = $type;
    $self->{'sectionname'}[0] = $type;
}
sub chapter_id {
    my ($self) = @_;
    unless ($self->{'chapter_id'}) {
      my $id;
      $id = $self->{'book_id'} . '-' if ($self->{'book_id'});
      if ($self->{'chapter_type'} eq 'preface') {
        $id .= 'PREFACE';
      } elsif ($self->{'chapter_type'} eq 'colophon') {
        $id .= 'COLOPHON';
      } elsif ($self->{'chapter_type'} eq 'appendix') {
        $id .= 'APP-' . $self->{'chapter_num'};
      } elsif ($self->{'chapter_type'} eq 'chapter') {
        $id .= 'CHP-' . $self->{'chapter_num'};
      }
      $self->{'chapter_id'} = $id;
    }
    return $self->{'chapter_id'};
}

# bypass built-in E<> handling to preserve entity encoding
sub _treat_Es {} 

1;

__END__

=head1 NAME

Pod::PseudoPod::DocBook -- format PseudoPod as DocBook

=head1 SYNOPSIS

  use Pod::PseudoPod::DocBook;

  my $parser = Pod::PseudoPod::DocBook->new();

  ...

  $parser->parse_file('path/to/file.pod');

Before sending in your manuscript, check that the formatter produced a
well-formed DocBook file with I<xmllint>:

  $ xmllint --noout --valid book.xml

=head1 DESCRIPTION

This class is a formatter that takes PseudoPod and renders it as
DocBook 4.4.

This is a subclass of L<Pod::PseudoPod> and inherits all its methods.

=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::Simple>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Allison Randal.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Allison Randal <allison@perl.org>

=cut

