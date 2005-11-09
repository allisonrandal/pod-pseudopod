use Module::Build;
my $build = Module::Build->new (
    module_name => 'Pod::PseudoPod',
    license => 'perl',
    requires => {
        'Pod::Simple'   => 3.02,
        'Text::Wrap'    => 98.112902,
    },
    recursive_test_files => 1,
    dist_author => 'Allison Randal (allison@perl.org)',
    dist_abstract => "A framework for parsing O'Reilly's PseudoPod",
);
$build->create_build_script;
