use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Pod::PseudoPod',
    VERSION_FROM => 'lib/Pod/PseudoPod.pm', # finds $VERSION
    PREREQ_PM    => {
        'Pod::Simple'   => 2.05,
        'Text::Wrap'    => 98.112902,
    },
    test =>
        {TESTS => 't/*.t t/*/*.t'},
    AUTHOR       => 'Allison Randal (allison@perl.org)',
    ABSTRACT     => "A framework for parsing O'Reilly's PseudoPod",
    'PL_FILES' => {}, # ignore the Build.PL file
);
