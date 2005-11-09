use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Pod::PseudoPod',
    VERSION_FROM => 'lib/Pod/PseudoPod.pm', # finds $VERSION
    PREREQ_PM    => {
        'Pod::Simple'   => 0.96,
        'Text::Wrap'    => 98.112902,
    },
    AUTHOR       => 'Allison Randal (al@shadowed.net)',
    ABSTRACT     => 'a framework for parsing PseudoPod documents',
);
