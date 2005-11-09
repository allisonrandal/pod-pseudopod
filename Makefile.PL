use ExtUtils::MakeMaker;

# The list of tests has to be explicitly generated on Win98.
my @tests;
for my $dir (qw(t t/pod_simple)) {
    opendir TESTS, $dir or die $!;
    push @tests, map { "$dir/$_" } grep { /\.t$/ } readdir TESTS;
    closedir TESTS;
}

WriteMakefile(
    NAME         => 'Pod::PseudoPod',
    VERSION_FROM => 'lib/Pod/PseudoPod.pm', # finds $VERSION
    PREREQ_PM    => {
        'Pod::Simple'   => 3.02,
        'Text::Wrap'    => 98.112902,
    },
    test =>
        {TESTS => "@tests"},
    AUTHOR       => 'Allison Randal (allison@perl.org)',
    ABSTRACT     => "A framework for parsing O'Reilly's PseudoPod",
    PL_FILES => {}, # ignore the Build.PL file
);
