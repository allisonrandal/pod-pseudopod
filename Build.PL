use Module::Build;
my $build = Module::Build->new (
   module_name => 'Pod::PseudoPod',
   license => 'perl',
   requires => {
        'Pod::Simple'   => 2.05,
        'Text::Wrap'    => 98.112902,
   },
   recursive_test_files => 1,
   create_makefile_pl => 'traditional',
);
$build->create_build_script;
