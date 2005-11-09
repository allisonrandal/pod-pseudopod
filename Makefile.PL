use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Pod::PseudoPod',
    VERSION_FROM => 'lib/Pod/PseudoPod.pm', # finds $VERSION
    PREREQ_PM    => {
        'Pod::Simple'   => 2.05,
        'Text::Wrap'    => 98.112902,
    },
    test =>
        {TESTS => 't/*.t t/*/*.t'},
    PREREQ_FATAL => 1,
    AUTHOR       => 'Allison Randal (allison@perl.org)',
    ABSTRACT     => 'a framework for parsing PseudoPod documents',
);
