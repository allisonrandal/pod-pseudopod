
use strict;
use Test;
BEGIN { plan tests => 26 };

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../../blib/lib';
}

use Pod::Simple::TextContent;
use Pod::PseudoPod::Text;

BEGIN {
  *mytime = defined(&Win32::GetTickCount)
    ? sub () {Win32::GetTickCount() / 1000}
    : sub () {time()}
}

$Pod::PseudoPod::Text::FREAKYMODE = 1;
use Pod::Simple::TiedOutFH ();

my $outfile = '10000';

chdir "t" or die "Can't chdir: $!" if -e "t";


foreach my $file (
  "pod_simple/test_junk1.pod",
  "pod_simple/test_junk2.pod",
  "pod_simple/test_old_perlcygwin.pod",
  "pod_simple/test_old_perlfaq3.pod",
  "pod_simple/test_old_perlvar.pod",
) {

  unless(-e $file) {
    ok 0;
    print "# But $file doesn't exist!!\n";
    exit 1;
  }

  my @out;
  my $precooked = $file;
  $precooked =~ s<\.pod><_out.txt>s;
  unless(-e $precooked) {
    ok 0;
    print "# But $precooked doesn't exist!!\n";
    exit 1;
  }
  
  print "#\n#\n#\n###################\n# $file\n";
  foreach my $class ('Pod::Simple::TextContent', 'Pod::PseudoPod::Text') {
    my $p = $class->new;
    push @out, '';
    $p->output_string(\$out[-1]);
    my $t = mytime();
    $p->parse_file($file);
    printf "# %s %s %sb, %.03fs\n",
     ref($p), $file, length($out[-1]), mytime() - $t ;
    ok 1;
  }

  print "# Reading $precooked...\n";
  open(IN, $precooked) or die "Can't read-open $precooked: $!";
  {
    local $/;
    push @out, <IN>;
  }
  close(IN);
  print "#   ", length($out[-1]), " bytes pulled in.\n";
  

  for (@out) { s/\s+/ /g; s/^\s+//s; s/\s+$//s; }

  my $faily = 0;
  print "#\n#Now comparing 1 and 2...\n";
  $faily += compare2($out[0], $out[1]);
  print "#\n#Now comparing 2 and 3...\n";
  $faily += compare2($out[1], $out[2]);
  print "#\n#Now comparing 1 and 3...\n";
  $faily += compare2($out[0], $out[2]);

  if($faily) {
    ++$outfile;
    
    my @outnames = map $outfile . $_ , qw(0 1);
    open(OUT2, ">$outnames[0].~out.txt") || die "Can't write-open $outnames[0].txt: $!";

    foreach my $out (@out) { push @outnames, $outnames[-1];  ++$outnames[-1] };
    pop @outnames;
    printf "# Writing to %s.txt .. %s.txt\n", $outnames[0], $outnames[-1];
    shift @outnames;
    
    binmode(OUT2);
    foreach my $out (@out) {
      my $outname = shift @outnames;
      open(OUT, ">$outname.txt") || die "Can't write-open $outname.txt: $!";
      binmode(OUT);
      print OUT  $out, "\n";
      print OUT2 $out, "\n";
      close(OUT);
    }
    close(OUT2);
  }
}

print "# Wrapping up... one for the road...\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";
exit;


sub compare2 {
  my @out = @_;
  if($out[0] eq $out[1]) {
    ok 1;
    return 0;
  } elsif( do{
    for ($out[0], $out[1]) { tr/ //d; };
    $out[0] eq $out[1];
  }){
    print "# Differ only in whitespace.\n";
    ok 1;
    return 0;
  } else {
    #ok $out[0], $out[1];
    
    my $x = $out[0] ^ $out[1];
    $x =~ m/^(\x00*)/s or die;
    my $at = length($1);
    print "# Difference at byte $at...\n";
    if($at > 10) {
      $at -= 5;
    }
    {
      print "# ", substr($out[0],$at,20), "\n";
      print "# ", substr($out[1],$at,20), "\n";
      print "#      ^...";
    }
    
    
    
    ok 0;
    printf "# Unequal lengths %s and %s\n", length($out[0]), length($out[1]);
    return 1;
  }
}


__END__

