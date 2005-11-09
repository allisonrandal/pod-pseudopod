
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
$VERSION = '0.10';

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }

@Known_formatting_codes = qw(A B C E F G H I L M N R S T U X Z);
%Known_formatting_codes = map(($_=>1), @Known_formatting_codes);
@Known_directives       = qw(head0 head1 head2 head3 head4 item over back headrow bodyrows row cell);
%Known_directives       = map(($_=>'Plain'), @Known_directives);

sub new {
  my $self = shift;
  my $new = $self->SUPER::new();

  $new->{'accept_codes'} = { map( ($_=>$_), @Known_formatting_codes ) };
  $new->{'accept_directives'} = \%Known_directives;
  return $new;
}

sub _handle_element_start {
  my ($self, $element, $flags) = @_;

  $element =~ tr/-:./__/;

  my $sub = $self->can('start_' . $element);
  $sub->($self,$flags) if $sub; 
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

sub nix_Z_codes { $_[0]{'nix_Z_codes'} = $_[1] }
sub codes_in_data { $_[0]{'codes_in_data'} = $_[1] }

# Largely copied from Pod::Simple::_treat_Zs, modified to optionally
# keep Z elements, and so it doesn't complain about Zs with content.
#
sub _treat_Zs {  # Nix Z<...>'s
  my($self,@stack) = @_;

  my($i, $treelet);
  my $start_line = $stack[0][1]{'start_line'};

  # A recursive algorithm implemented iteratively!  Whee!

  while($treelet = shift @stack) {
    for($i = 2; $i < @$treelet; ++$i) { # iterate over children
      next unless ref $treelet->[$i];  # text nodes are uninteresting
      unless($treelet->[$i][0] eq 'Z') {
        unshift @stack, $treelet->[$i]; # recurse
        next;
      }
        
      if ($self->{'nix_Z_codes'}) {
        #DEBUG > 1 and print "Nixing Z node @{$treelet->[$i]}\n";
        splice(@$treelet, $i, 1); # thereby just nix this node.
        --$i;
      }

    }
  }
  
  return;
}

# The _ponder_* methods override _ponder_paragraph_buffer from
# Pod::Simple::BlackBox. It was so large that it wasn't much fun to
# work with, so I split it out into multiple methods. Many of the
# _ponder_* methods will move out of Pod::PseudoPod if the patch I
# sent in for Pod::Simple::BlackBox goes into the next version.

sub _ponder_paragraph_buffer {

  # Para-token types as found in the buffer.
  #   ~Verbatim, ~Para, ~end, =head1..4, =for, =begin, =end,
  #   =over, =back, =item
  #   and the null =pod (to be complained about if over one line)
  #
  # "~data" paragraphs are something we generate at this level, depending on
  # a currently open =over region

  # Events fired:  Begin and end for:
  #                   directivename (like head1 .. head4), item, extend,
  #                   for (from =begin...=end, =for),
  #                   over-bullet, over-number, over-text, over-block,
  #                   item-bullet, item-number, item-text,
  #                   Document,
  #                   Data, Para, Verbatim
  #                   B, C, longdirname (TODO -- wha?), etc. for all directives
  # 

  my $self = $_[0];
  my $paras;
  return unless @{$paras = $self->{'paras'}};
  my $curr_open = ($self->{'curr_open'} ||= []);

  DEBUG > 10 and print "# Paragraph buffer: <<", pretty($paras), ">>\n";

  # We have something in our buffer.  So apparently the document has started.
  unless($self->{'doc_has_started'}) {
    $self->{'doc_has_started'} = 1;
    
    my $starting_contentless;
    $starting_contentless =
     (
       !@$curr_open  
       and @$paras and ! grep $_->[0] ne '~end', @$paras
        # i.e., if the paras is all ~ends
     )
    ;
    DEBUG and print "# Starting ", 
      $starting_contentless ? 'contentless' : 'contentful',
      " document\n"
    ;
    
    $self->_handle_element_start('Document',
      {
        'start_line' => $paras->[0][1]{'start_line'},
        $starting_contentless ? ( 'contentless' => 1 ) : (),
      },
    );
  }

  my($para, $para_type);
  while(@$paras) {
    last if @$paras == 1 and
      ( $paras->[0][0] eq '=over' or $paras->[0][0] eq '~Verbatim'
        or $paras->[0][0] eq '=item' )
    ;
    # Those're the three kinds of paragraphs that require lookahead.
    #   Actually, an "=item Foo" inside an <over type=text> region
    #   and any =item inside an <over type=block> region (rare)
    #   don't require any lookahead, but all others (bullets
    #   and numbers) do.

# TODO: winge about many kinds of directives in non-resolving =for regions?
# TODO: many?  like what?  =head1 etc?

    $para = shift @$paras;
    $para_type = $para->[0];

    DEBUG > 1 and print "Pondering a $para_type paragraph, given the stack: (",
      $self->_dump_curr_open(), ")\n";
    
    if($para_type eq '=for') {
      next if $self->_ponder_for($para,$curr_open,$paras);
    } elsif($para_type eq '=begin') {
      next if $self->_ponder_begin($para,$curr_open,$paras);
    } elsif($para_type eq '=end') {
      next if $self->_ponder_end($para,$curr_open,$paras);
    } elsif($para_type eq '~end') { # The virtual end-document signal
      next if $self->_ponder_doc_end($para,$curr_open,$paras);
    }


    # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    #~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    if(grep $_->[1]{'~ignore'}, @$curr_open) {
      DEBUG > 1 and
       print "Skipping $para_type paragraph because in ignore mode.\n";
      next;
    }
    #~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

    if($para_type eq '=pod') {
      $self->_ponder_pod($para,$curr_open,$paras);
    } elsif($para_type eq '=over') {
      next if $self->_ponder_over($para,$curr_open,$paras);
    } elsif($para_type eq '=back') {
      next if $self->_ponder_back($para,$curr_open,$paras);
    } elsif($para_type eq '=row') {
      next if $self->_ponder_row_start($para,$curr_open,$paras);
      
    } else {
      # All non-magical codes!!!
      
      # Here we start using $para_type for our own twisted purposes, to
      #  mean how it should get treated, not as what the element name
      #  should be.

      DEBUG > 1 and print "Pondering non-magical $para_type\n";

      # Enforce some =headN discipline
      if($para_type =~ m/^=head\d$/s
         and ! $self->{'accept_heads_anywhere'}
         and @$curr_open
         and $curr_open->[-1][0] eq '=over'
      ) {
        DEBUG > 2 and print "'=$para_type' inside an '=over'!\n";
        $self->whine(
          $para->[1]{'start_line'},
          "You forgot a '=back' before '$para_type'"
        );
        unshift @$paras, ['=back', {}, ''], $para;   # close the =over
        next;
      }


      if($para_type eq '=item') {
        next if $self->_ponder_item($para,$curr_open,$paras);
        $para_type = 'Plain';
        # Now fall thru and process it.

      } elsif($para_type eq '=extend') {
        # Well, might as well implement it here.
        $self->_ponder_extend($para);
        next;  # and skip
      } elsif($para_type eq '=encoding') {
        # Not actually acted on here, but we catch errors here.
        $self->_handle_encoding_second_level($para);

        next;  # and skip
      } elsif($para_type eq '~Verbatim') {
        $para->[0] = 'Verbatim';
        $para_type = '?Verbatim';
      } elsif($para_type eq '~Para') {
        $para->[0] = 'Para';
        $para_type = '?Plain';
      } elsif($para_type eq 'Data') {
        $para->[0] = 'Data';
        $para_type = '?Data';
      } elsif( $para_type =~ s/^=//s
        and defined( $para_type = $self->{'accept_directives'}{$para_type} )
      ) {
        DEBUG > 1 and print " Pondering known directive ${$para}[0] as $para_type\n";
      } else {
        # An unknown directive!
        DEBUG > 1 and printf "Unhandled directive %s (Handled: %s)\n",
         $para->[0], join(' ', sort keys %{$self->{'accept_directives'}} )
        ;
        $self->whine(
          $para->[1]{'start_line'},
          "Unknown directive: $para->[0]"
        );

        # And maybe treat it as text instead of just letting it go?
        next;
      }

      if($para_type =~ s/^\?//s) {
        if(! @$curr_open) {  # usual case
          DEBUG and print "Treating $para_type paragraph as such because stack is empty.\n";
        } else {
          my @fors = grep $_->[0] eq '=for', @$curr_open;
          DEBUG > 1 and print "Containing fors: ",
            join(',', map $_->[1]{'target'}, @fors), "\n";
          
          if(! @fors) {
            DEBUG and print "Treating $para_type paragraph as such because stack has no =for's\n";
            
          #} elsif(grep $_->[1]{'~resolve'}, @fors) {
          #} elsif(not grep !$_->[1]{'~resolve'}, @fors) {
          } elsif( $fors[-1][1]{'~resolve'} ) {
            # Look to the immediately containing for
          
            if($para_type eq 'Data') {
              DEBUG and print "Treating Data paragraph as Plain/Verbatim because the containing =for ($fors[-1][1]{'target'}) is a resolver\n";
              $para->[0] = 'Para';
              $para_type = 'Plain';
            } else {
              DEBUG and print "Treating $para_type paragraph as such because the containing =for ($fors[-1][1]{'target'}) is a resolver\n";
            }
          } else {
            DEBUG and print "Treating $para_type paragraph as Data because the containing =for ($fors[-1][1]{'target'}) is a non-resolver\n";
            $para->[0] = $para_type = 'Data';
          }
        }
      }

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if($para_type eq 'Plain') {
        $self->_ponder_Plain($para);
      } elsif($para_type eq 'Verbatim') {
        $self->_ponder_Verbatim($para);
      } elsif($para_type eq 'Data') {
        $self->_ponder_Data($para);
      } else {
        die "\$para type is $para_type -- how did that happen?";
        # Shouldn't happen.
      }

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      $para->[0] =~ s/^[~=]//s;

      DEBUG and print "\n", Pod::Simple::BlackBox::pretty($para), "\n";

      # traverse the treelet (which might well be just one string scalar)
      $self->{'content_seen'} ||= 1;
      $self->_traverse_treelet_bit(@$para);
    }
  }
  
  return;
}

sub _ponder_for {
  my ($self,$para,$curr_open,$paras) = @_;

  # Fake it out as a begin/end
  my $target;

  if(grep $_->[1]{'~ignore'}, @$curr_open) {
    DEBUG > 1 and print "Ignoring ignorable =for\n";
    return 1;
  }

  for(my $i = 2; $i < @$para; ++$i) {
    if($para->[$i] =~ s/^\s*(\S+)\s*//s) {
      $target = $1;
      last;
    }
  }
  unless(defined $target) {
    $self->whine(
      $para->[1]{'start_line'},
      "=for without a target?"
    );
    return 1;
  }

  if (@$para > 3 or $para->[2]) {
    # This is an ordinary =for and should be handled in the Pod::Simple way

    DEBUG > 1 and
     print "Faking out a =for $target as a =begin $target / =end $target\n";
  
    $para->[0] = 'Data';
  
    unshift @$paras,
      ['=begin',
        {'start_line' => $para->[1]{'start_line'}, '~really' => '=for'},
        $target,
      ],
      $para,
      ['=end',
        {'start_line' => $para->[1]{'start_line'}, '~really' => '=for'},
        $target,
      ],
    ;
  
  } else {
    # This is a =for with an =end tag

    DEBUG > 1 and
     print "Faking out a =for $target as a =begin $target\n";
  
    unshift @$paras,
      ['=begin',
        {'start_line' => $para->[1]{'start_line'}, '~really' => '=for'},
        $target,
      ],
    ;

  }
  return 1;
}

sub _ponder_begin {
  my ($self,$para,$curr_open,$paras) = @_;

  unless ($para->[2] =~ /^\s*(?:table|sidebar|figure)/) {
    return $self->_super_ponder_begin($para,$curr_open,$paras);
  }

  my $content = join ' ', splice @$para, 2;
  $content =~ s/^\s+//s;
  $content =~ s/\s+$//s;

  my ($target, $title) = $content =~ m/^(\S+)\s*(.*)$/;
  $title =~ s/^(picture|html)\s*// if ($target eq 'table');
  $para->[1]{'title'} = $title if ($title);
  $para->[1]{'target'} = $target;  # without any ':'

  return 1 unless $self->{'accept_targets'}{$target};

  $para->[0] = '=for';  # Just what we happen to call these, internally
  $para->[1]{'~really'} ||= '=begin';
#  $para->[1]{'~ignore'}  = 0;
  $para->[1]{'~resolve'} = 1;

  push @$curr_open, $para;
  $self->{'content_seen'} ||= 1;
  $self->_handle_element_start($target, $para->[1]);

  return 1;
}

# This will eventually be SUPER::_ponder_begin, if my patch is added
# to the next version of Pod::Simple.
sub _super_ponder_begin {
  my ($self,$para,$curr_open,$paras) = @_;
  my $content = join ' ', splice @$para, 2;
  $content =~ s/^\s+//s;
  $content =~ s/\s+$//s;
  unless(length($content)) {
    $self->whine(
      $para->[1]{'start_line'},
      "=begin without a target?"
    );
    DEBUG and print "Ignoring targetless =begin\n";
    return 1;
  }
  
  unless($content =~ m/^\S+$/s) {  # i.e., unless it's one word
    $self->whine(
      $para->[1]{'start_line'},
      "'=begin' only takes one parameter, not several as in '=begin $content'"
    );
    DEBUG and print "Ignoring unintelligible =begin $content\n";
    return 1;
  }


  $para->[1]{'target'} = $content;  # without any ':'

  $content =~ s/^:!/!:/s;
  my $neg;  # whether this is a negation-match
  $neg = 1        if $content =~ s/^!//s;
  my $to_resolve;  # whether to process formatting codes
  $to_resolve = 1 if $content =~ s/^://s;
  
  my $dont_ignore; # whether this target matches us
  
  foreach my $target_name (
    split(',', $content, -1),
    $neg ? () : '*'
  ) {
    DEBUG > 2 and
     print " Considering whether =begin $content matches $target_name\n";
    next unless $self->{'accept_targets'}{$target_name};
    
    DEBUG > 2 and
     print "  It DOES match the acceptable target $target_name!\n";
    $to_resolve = 1
      if $self->{'accept_targets'}{$target_name} eq 'force_resolve';
    $dont_ignore = 1;
    $para->[1]{'target_matching'} = $target_name;
    last; # stop looking at other target names
  }

  if($neg) {
    if( $dont_ignore ) {
      $dont_ignore = '';
      delete $para->[1]{'target_matching'};
      DEBUG > 2 and print " But the leading ! means that this is a NON-match!\n";
    } else {
      $dont_ignore = 1;
      $para->[1]{'target_matching'} = '!';
      DEBUG > 2 and print " But the leading ! means that this IS a match!\n";
    }
  }

  $para->[0] = '=for';  # Just what we happen to call these, internally
  $para->[1]{'~really'} ||= '=begin';
  $para->[1]{'~ignore'}   = (! $dont_ignore) || 0;
  $para->[1]{'~resolve'}  = $to_resolve || 0;

  DEBUG > 1 and print " Making note to ", $dont_ignore ? 'not ' : '',
    "ignore contents of this region\n";
  DEBUG > 1 and $dont_ignore and print " Making note to treat contents as ",
    ($to_resolve ? 'verbatim/plain' : 'data'), " paragraphs\n";
  DEBUG > 1 and print " (Stack now: ", $self->_dump_curr_open(), ")\n";

  push @$curr_open, $para;
  if(!$dont_ignore or scalar grep $_->[1]{'~ignore'}, @$curr_open) {
    DEBUG > 1 and print "Ignoring ignorable =begin\n";
  } else {
    $self->{'content_seen'} ||= 1;
    $self->_handle_element_start((my $scratch='for'), $para->[1]);
  }

  return 1;
}

sub _ponder_end {
  my ($self,$para,$curr_open,$paras) = @_;
  my $content = join ' ', splice @$para, 2;
  $content =~ s/^\s+//s;
  $content =~ s/\s+$//s;
  DEBUG and print "Ogling '=end $content' directive\n";
  
  unless(length($content)) {
    if (@$curr_open and $curr_open->[-1][1]{'~really'} eq '=for') {
      # =for allows an empty =end directive
      $content = $curr_open->[-1][1]{'target'};
    } else {
      # Everything else should complain about an empty =end directive
      my $complaint = "'=end' without a target?";
      if ( @$curr_open and $curr_open->[-1][0] eq '=for' ) {
        $complaint .= " (Should be \"=end " . $curr_open->[-1][1]{'target'} . '")';
      }
      $self->whine( $para->[1]{'start_line'}, $complaint);
      DEBUG and print "Ignoring targetless =end\n";
      return 1;
    }
  }
  
  unless($content =~ m/^\S+$/) {  # i.e., unless it's one word
    $self->whine(
      $para->[1]{'start_line'},
      "'=end $content' is invalid.  (Stack: "
      . $self->_dump_curr_open() . ')'
    );
    DEBUG and print "Ignoring mistargetted =end $content\n";
    return 1;
  }
  
  $self->_ponder_row_end($para,$curr_open,$paras) if $content eq 'table';

  unless(@$curr_open and $curr_open->[-1][0] eq '=for') {
    $self->whine(
      $para->[1]{'start_line'},
      "=end $content without matching =begin.  (Stack: "
      . $self->_dump_curr_open() . ')'
    );
    DEBUG and print "Ignoring mistargetted =end $content\n";
    return 1;
  }
  
  unless($content eq $curr_open->[-1][1]{'target'}) {
    if ($content eq 'for' and $curr_open->[-1][1]{'~really'} eq '=for') {
      # =for allows a "=end for" directive
      $content = $curr_open->[-1][1]{'target'};
    } else {
      $self->whine(
        $para->[1]{'start_line'},
        "=end $content doesn't match =begin " 
        . $curr_open->[-1][1]{'target'}
        . ".  (Stack: "
        . $self->_dump_curr_open() . ')'
      );
      DEBUG and print "Ignoring mistargetted =end $content at line $para->[1]{'start_line'}\n";
      return 1;
    }
  }

  # Else it's okay to close...
  if(grep $_->[1]{'~ignore'}, @$curr_open) {
    DEBUG > 1 and print "Not firing any event for this =end $content because in an ignored region\n";
    # And that may be because of this to-be-closed =for region, or some
    #  other one, but it doesn't matter.
  } else {
    $curr_open->[-1][1]{'start_line'} = $para->[1]{'start_line'};
      # what's that for?
    
    $self->{'content_seen'} ||= 1;
    if ($content eq 'table' or $content eq 'sidebar' or $content eq 'figure') {
      $self->_handle_element_end( $content );
    } else {
      $self->_handle_element_end( 'for' );
    }
  }
  DEBUG > 1 and print "Popping $curr_open->[-1][0] $curr_open->[-1][1]{'target'} because of =end $content\n";
  pop @$curr_open;

  return 1;
} 

sub _ponder_doc_end {
  my ($self,$para,$curr_open,$paras) = @_;
  if(@$curr_open) { # Deal with things left open
    DEBUG and print "Stack is nonempty at end-document: (",
      $self->_dump_curr_open(), ")\n";
      
    DEBUG > 9 and print "Stack: ", pretty($curr_open), "\n";
    unshift @$paras, $self->_closers_for_all_curr_open;
    # Make sure there is exactly one ~end in the parastack, at the end:
    @$paras = grep $_->[0] ne '~end', @$paras;
    push @$paras, $para, $para;
     # We need two -- once for the next cycle where we
     #  generate errata, and then another to be at the end
     #  when that loop back around to process the errata.
    return 1;
    
  } else {
    DEBUG and print "Okay, stack is empty now.\n";
  }
  
  # Try generating errata section, if applicable
  unless($self->{'~tried_gen_errata'}) {
    $self->{'~tried_gen_errata'} = 1;
    my @extras = $self->_gen_errata();
    if(@extras) {
      unshift @$paras, @extras;
      DEBUG and print "Generated errata... relooping...\n";
      return 1;  # I.e., loop around again to process these fake-o paragraphs
    }
  }
  
  splice @$paras; # Well, that's that for this paragraph buffer.
  DEBUG and print "Throwing end-document event.\n";

  $self->_handle_element_end( 'Document' );
  return 1; # Hasta la byebye
}

sub _ponder_pod {
  my ($self,$para,$curr_open,$paras) = @_;
  $self->whine(
    $para->[1]{'start_line'},
    "=pod directives shouldn't be over one line long!  Ignoring all "
     . (@$para - 2) . " lines of content"
  ) if @$para > 3;
  # Content is always ignored.
  return;
}

sub _ponder_over {
  my ($self,$para,$curr_open,$paras) = @_;
  return 1 unless @$paras;
  my $list_type;

  if($paras->[0][0] eq '=item') { # most common case
    $list_type = $self->_get_initial_item_type($paras->[0]);

  } elsif($paras->[0][0] eq '=back') {
    # Ignore empty lists.  TODO: make this an option?
    shift @$paras;
    return 1;
    
  } elsif($paras->[0][0] eq '~end') {
    $self->whine(
      $para->[1]{'start_line'},
      "=over is the last thing in the document?!"
    );
    return 1; # But feh, ignore it.
  } else {
    $list_type = 'block';
  }
  $para->[1]{'~type'} = $list_type;
  push @$curr_open, $para;
   # yes, we reuse the paragraph as a stack item
  
  my $content = join ' ', splice @$para, 2;
  my $overness;
  if($content =~ m/^\s*$/s) {
    $para->[1]{'indent'} = 4;
  } elsif($content =~ m/^\s*((?:\d*\.)?\d+)\s*$/s) {
    no integer;
    $para->[1]{'indent'} = $1;
    if($1 == 0) {
      $self->whine(
        $para->[1]{'start_line'},
        "Can't have a 0 in =over $content"
      );
      $para->[1]{'indent'} = 4;
    }
  } else {
    $self->whine(
      $para->[1]{'start_line'},
      "=over should be: '=over' or '=over positive_number'"
    );
    $para->[1]{'indent'} = 4;
  }
  DEBUG > 1 and print "=over found of type $list_type\n";
  
  $self->{'content_seen'} ||= 1;
  $self->_handle_element_start('over-' . $list_type, $para->[1]);

  return;
}

sub _ponder_row_start {
  my ($self,$para,$curr_open,$paras) = @_;

  $self->_ponder_row_end($para,$curr_open,$paras);

  push @$curr_open, $para;

  $self->{'content_seen'} ||= 1;
  $self->_handle_element_start('row', $para->[1]);

  return 1;
}

sub _ponder_row_end {
  my ($self,$para,$curr_open,$paras) = @_;
  # PseudoPod doesn't have a row closing entity, so "=row" and "=end
  # table" have to double for it.

  if(@$curr_open and $curr_open->[-1][0] eq '=row') {
    $self->{'content_seen'} ||= 1;
    my $over = pop @$curr_open;
    $self->_handle_element_end( 'row' );
  }
  return 1;
}

sub _ponder_back {
  my ($self,$para,$curr_open,$paras) = @_;
  # TODO: fire off </item-number> or </item-bullet> or </item-text> ??

  my $content = join ' ', splice @$para, 2;
  if($content =~ m/\S/) {
    $self->whine(
      $para->[1]{'start_line'},
      "=back doesn't take any parameters, but you said =back $content"
    );
  }

  if(@$curr_open and $curr_open->[-1][0] eq '=over') {
    DEBUG > 1 and print "=back happily closes matching =over\n";
    # Expected case: we're closing the most recently opened thing
    #my $over = pop @$curr_open;
    $self->{'content_seen'} ||= 1;
    $self->_handle_element_end('over-' . ( (pop @$curr_open)->[1]{'~type'} ));
  } else {
    DEBUG > 1 and print "=back found without a matching =over.  Stack: (",
        join(', ', map $_->[0], @$curr_open), ").\n";
    $self->whine(
      $para->[1]{'start_line'},
      '=back without =over'
    );
    return 1; # and ignore it
  }
}

sub _ponder_item {
  my ($self,$para,$curr_open,$paras) = @_;
  my $over;
  unless(@$curr_open and ($over = $curr_open->[-1])->[0] eq '=over') {
    $self->whine(
      $para->[1]{'start_line'},
      "'=item' outside of any '=over'"
    );
    unshift @$paras,
      ['=over', {'start_line' => $para->[1]{'start_line'}}, ''],
      $para
    ;
    return 1;
  }
  
  
  my $over_type = $over->[1]{'~type'};
  
  if(!$over_type) {
    # Shouldn't happen1
    die "Typeless over in stack, starting at line "
     . $over->[1]{'start_line'};

  } elsif($over_type eq 'block') {
    unless($curr_open->[-1][1]{'~bitched_about'}) {
      $curr_open->[-1][1]{'~bitched_about'} = 1;
      $self->whine(
        $curr_open->[-1][1]{'start_line'},
        "You can't have =items (as at line "
        . $para->[1]{'start_line'}
        . ") unless the first thing after the =over is an =item"
      );
    }
    # Just turn it into a paragraph and reconsider it
    $para->[0] = '~Para';
    unshift @$paras, $para;
    return 1;

  } elsif($over_type eq 'text') {
    my $item_type = $self->_get_item_type($para);
      # That kills the content of the item if it's a number or bullet.
    DEBUG and print " Item is of type ", $para->[0], " under $over_type\n";
    
    if($item_type eq 'text') {
      # Nothing special needs doing for 'text'
    } elsif($item_type eq 'number' or $item_type eq 'bullet') {
      die "Unknown item type $item_type"
       unless $item_type eq 'number' or $item_type eq 'bullet';
      # Undo our clobbering:
      push @$para, $para->[1]{'~orig_content'};
      delete $para->[1]{'number'};
       # Only a PROPER item-number element is allowed
       #  to have a number attribute.
    } else {
      die "Unhandled item type $item_type"; # should never happen
    }
    
    # =item-text thingies don't need any assimilation, it seems.

  } elsif($over_type eq 'number') {
    my $item_type = $self->_get_item_type($para);
      # That kills the content of the item if it's a number or bullet.
    DEBUG and print " Item is of type ", $para->[0], " under $over_type\n";
    
    my $expected_value = ++ $curr_open->[-1][1]{'~counter'};
    
    if($item_type eq 'bullet') {
      # Hm, it's not numeric.  Correct for this.
      $para->[1]{'number'} = $expected_value;
      $self->whine(
        $para->[1]{'start_line'},
        "Expected '=item $expected_value'"
      );
      push @$para, $para->[1]{'~orig_content'};
        # restore the bullet, blocking the assimilation of next para

    } elsif($item_type eq 'text') {
      # Hm, it's not numeric.  Correct for this.
      $para->[1]{'number'} = $expected_value;
      $self->whine(
        $para->[1]{'start_line'},
        "Expected '=item $expected_value'"
      );
      # Text content will still be there and will block next ~Para

    } elsif($item_type ne 'number') {
      die "Unknown item type $item_type"; # should never happen

    } elsif($expected_value == $para->[1]{'number'}) {
      DEBUG > 1 and print " Numeric item has the expected value of $expected_value\n";
      
    } else {
      DEBUG > 1 and print " Numeric item has ", $para->[1]{'number'},
       " instead of the expected value of $expected_value\n";
      $self->whine(
        $para->[1]{'start_line'},
        "You have '=item " . $para->[1]{'number'} .
        "' instead of the expected '=item $expected_value'"
      );
      $para->[1]{'number'} = $expected_value;  # correcting!!
    }
      
    if(@$para == 2) {
      # For the cases where we /didn't/ push to @$para
      if($paras->[0][0] eq '~Para') {
        DEBUG and print "Assimilating following ~Para content into $over_type item\n";
        push @$para, splice @{shift @$paras},2;
      } else {
        DEBUG and print "Can't assimilate following ", $paras->[0][0], "\n";
        push @$para, '';  # Just so it's not contentless
      }
    }


  } elsif($over_type eq 'bullet') {
    my $item_type = $self->_get_item_type($para);
      # That kills the content of the item if it's a number or bullet.
    DEBUG and print " Item is of type ", $para->[0], " under $over_type\n";
    
    if($item_type eq 'bullet') {
      # as expected!

      if( $para->[1]{'~_freaky_para_hack'} ) {
        DEBUG and print "Accomodating '=item * Foo' tolerance hack.\n";
        push @$para, delete $para->[1]{'~_freaky_para_hack'};
      }

    } elsif($item_type eq 'number') {
      $self->whine(
        $para->[1]{'start_line'},
        "Expected '=item *'"
      );
      push @$para, $para->[1]{'~orig_content'};
       # and block assimilation of the next paragraph
      delete $para->[1]{'number'};
       # Only a PROPER item-number element is allowed
       #  to have a number attribute.
    } elsif($item_type eq 'text') {
      $self->whine(
        $para->[1]{'start_line'},
        "Expected '=item *'"
      );
       # But doesn't need processing.  But it'll block assimilation
       #  of the next para.
    } else {
      die "Unhandled item type $item_type"; # should never happen
    }

    if(@$para == 2) {
      # For the cases where we /didn't/ push to @$para
      if($paras->[0][0] eq '~Para') {
        DEBUG and print "Assimilating following ~Para content into $over_type item\n";
        push @$para, splice @{shift @$paras},2;
      } else {
        DEBUG and print "Can't assimilate following ", $paras->[0][0], "\n";
        push @$para, '';  # Just so it's not contentless
      }
    }

  } else {
    die "Unhandled =over type \"$over_type\"?";
    # Shouldn't happen!
  }
  $para->[0] .= '-' . $over_type;

  return;
}

sub _ponder_Plain {
  my ($self,$para) = @_;
  DEBUG and print " giving plain treatment...\n";
  unless( @$para == 2 or ( @$para == 3 and $para->[2] eq '' )
    or $para->[1]{'~cooked'}
  ) {
    push @$para,
    @{$self->_make_treelet(
      join("\n", splice(@$para, 2)),
      $para->[1]{'start_line'}
    )};
  }
  # Empty paragraphs don't need a treelet for any reason I can see.
  # And precooked paragraphs already have a treelet.
  return;
}

sub _ponder_Verbatim {
  my ($self,$para) = @_;
  DEBUG and print " giving verbatim treatment...\n";

  $para->[1]{'xml:space'} = 'preserve';
  for(my $i = 2; $i < @$para; $i++) {
    foreach my $line ($para->[$i]) { # just for aliasing
      while( $line =~
        # Sort of adapted from Text::Tabs -- yes, it's hardwired in that
        # tabs are at every EIGHTH column.  For portability, it has to be
        # one setting everywhere, and 8th wins.
        s/^([^\t]*)(\t+)/$1.(" " x ((length($2)<<3)-(length($1)&7)))/e
      ) {}

      # TODO: whinge about (or otherwise treat) unindented or overlong lines

    }
  }
  
  # Now the VerbatimFormatted hoodoo...
  if( $self->{'accept_codes'} and
      $self->{'accept_codes'}{'VerbatimFormatted'}
  ) {
    while(@$para > 3 and $para->[-1] !~ m/\S/) { pop @$para }
     # Kill any number of terminal newlines
    $self->_verbatim_format($para);
  } elsif ($self->{'codes_in_data'}) {
    push @$para,
    @{$self->_make_treelet(
      join("\n", splice(@$para, 2)),
      $para->[1]{'start_line'}, $para->[1]{'xml:space'}
    )};
    $para->[-1] =~ s/\n+$//s; # Kill any number of terminal newlines
  } else {
    push @$para, join "\n", splice(@$para, 2) if @$para > 3;
    $para->[-1] =~ s/\n+$//s; # Kill any number of terminal newlines
  }
  return;
}

sub _ponder_Data {
  my ($self,$para) = @_;
  DEBUG and print " giving data treatment...\n";
  $para->[1]{'xml:space'} = 'preserve';
  push @$para, join "\n", splice(@$para, 2) if @$para > 3;
  return;
}

sub _treelet_from_formatting_codes {
  # Given a paragraph, returns a treelet.  Full of scary tokenizing code.
  #  Like [ '~Top', {'start_line' => $start_line},
  #            "I like ",
  #            [ 'B', {}, "pie" ],
  #            "!"
  #       ]
  
  my($self, $para, $start_line, $preserve_space) = @_;
  my $treelet = ['~Top', {'start_line' => $start_line},];
  
  unless ($preserve_space) {
    $para =~ s/\s+/ /g; # collapse and trim all whitespace first.
    $para =~ s/ $//g;
    $para =~ s/^ //g;
  }
  
  # Only apparent problem the above code is that N<<  >> turns into
  # N<< >>.  But then, word wrapping does that too!  So don't do that!
  
  my @stack;
  my @lineage = ($treelet);

  DEBUG > 4 and print "Paragraph:\n$para\n\n";
  
  while($para =~  # Here begins our frightening tokenizer RE.
    m/\G
      (?:
        ([A-Z]<(<+\ )?) # that's $1 and $2 for both kinds of start-codes
        |
        (\ >{2,})       # $3: end-codes of the type " >>", " >>>", etc.
        |
        (\ ?>)          # $4: simple end-codes
        |
        (               # $5: stuff containing no start-codes or end-codes
          (?:
            [^A-Z\ >]+
            |
            (?:
              [A-Z](?!<)
            )
            |
            (?:
              \ (?!>)
            )
          )+
        )
      )
    /xgo
  ) {
    DEBUG > 4 and print "\nParagraphic tokenstack = (@stack)\n";
    if(defined $1) {
      if(defined $2) {
        DEBUG > 3 and print "Found complex start-text code \"$1\"\n";
        push @stack, length($1) - 1; 
          # length of the necessary complex end-code string
      } else {
        DEBUG > 3 and print "Found simple start-text code \"$1\"\n";
        push @stack, 0;  # signal that we're looking for simple
      }
      push @lineage, [ substr($1,0,1), {}, ];  # new node object
      push @{ $lineage[-2] }, $lineage[-1];
      
    } elsif(defined $3) {
      DEBUG > 3 and print "Found apparent complex end-text code \"$3\"\n";
      # This is where it gets messy...
      if(! @stack) {
        # We saw " >>>>" but needed nothing.  This is ALL just stuff then.
        DEBUG > 4 and print " But it's really just stuff.\n";
        push @{ $lineage[-1] }, $3;
        next;
      } elsif(!$stack[-1]) {
        # We saw " >>>>" but needed only ">".  Back pos up.
        DEBUG > 4 and print " And that's more than we needed to close simple.\n";
        push @{ $lineage[-1] }, ' '; # That was a for-real space, too.
        pos($para) = pos($para) - length($3) + 2;
      } elsif($stack[-1] == length($3)) {
        # We found " >>>>", and it was exactly what we needed.  Commonest case.
        DEBUG > 4 and print " And that's exactly what we needed to close complex.\n";
      } elsif($stack[-1] < length($3)) {
        # We saw " >>>>" but needed only " >>".  Back pos up.
        DEBUG > 4 and print " And that's more than we needed to close complex.\n";
        pos($para) = pos($para) - length($3) + $stack[-1];
      } else {
        # We saw " >>>>" but needed " >>>>>>".  So this is all just stuff!
        DEBUG > 4 and print " But it's really just stuff, because we needed more.\n";
        push @{ $lineage[-1] }, $3;
        next;
      }
      #print "\nHOOBOY ", scalar(@{$lineage[-1]}), "!!!\n";
      
      push @{ $lineage[-1] }, '' if 2 == @{ $lineage[-1] };
      # Keep the element from being childless
      
      pop @stack;
      pop @lineage;
      
    } elsif(defined $4) {
      DEBUG > 3 and print "Found apparent simple end-text code \"$4\"\n";

      if(@stack and ! $stack[-1]) {
        # We're indeed expecting a simple end-code
        DEBUG > 4 and print " It's indeed an end-code.\n";

        if(length($4) == 2) { # There was a space there: " >"
          push @{ $lineage[-1] }, ' ';
        } elsif( 2 == @{ $lineage[-1] } ) { # Closing a childless element
          push @{ $lineage[-1] }, ''; # keep it from being really childless
        }

        pop @stack;
        pop @lineage;
      } else {
        DEBUG > 4 and print " It's just stuff.\n";
        push @{ $lineage[-1] }, $4;
      }

    } elsif(defined $5) {
      DEBUG > 3 and print "Found stuff \"$5\"\n";
      push @{ $lineage[-1] }, $5;
      
    } else {
      # should never ever ever ever happen
      DEBUG and print "AYYAYAAAAA at line ", __LINE__, "\n";
      die "SPORK 512512!";
    }
  }

  if(@stack) { # Uhoh, some sequences weren't closed.
    my $x= "...";
    while(@stack) {
      push @{ $lineage[-1] }, '' if 2 == @{ $lineage[-1] };
      # Hmmmmm!

      my $code         = (pop @lineage)->[0];
      my $ender_length =  pop @stack;
      if($ender_length) {
        --$ender_length;
        $x = $code . ("<" x $ender_length) . " $x " . (">" x $ender_length);
      } else {
        $x = $code . "<$x>";
      }
    }
    DEBUG > 1 and print "Unterminated $x sequence\n";
    $self->whine($start_line,
      "Unterminated $x sequence",
    );
  }
  
  return $treelet;
}

1; 

__END__

=head1 NAME

Pod::PseudoPod - A framework for parsing O'Reilly's PseudoPod

=head1 SYNOPSIS

  use strict;
  package SomePseudoPodFormatter;
  use base qw(Pod::PseudoPod);

  sub handle_text {
    my($self, $text) = @_;
    ...
  }

  sub start_head1 {
    my($self, $flags) = @_;
    ...
  }
  sub end_head1 {
    my($self) = @_;
   ...
  }

  ...and start_*/end_* methods for whatever other events you
  want to catch.

=head1 DESCRIPTION

PseudoPod is an extended set of Pod tags used by O'Reilly and
Associates publishing for book manuscripts. Standard Pod doesn't have
all the markup options you need to mark up files for publishing
production. PseudoPod adds a few extra tags for footnotes, tables,
sidebars, etc.

This class adds parsing support for the PseudoPod tags. It also
overrides Pod::Simple's C<_handle_element_start>, C<_handle_text>, and
C<_handle_element_end> methods so that parser events are turned into
method calls.

In general, you'll only want to use this module as the base class for
a PseudoPod formatter/processor.

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::PseudoPod::HTML>, L<Pod::PseudoPod::Tutorial>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Allison Randal.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Allison Randal <allison@perl.org>

=cut

