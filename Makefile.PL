use inc::Module::Install;
name 'DBIx-Skinny-Profiler-Plus-NestedTransaction';
all_from 'lib/DBIx/Skinny/Plus/NestedTransaction.pm';

requires 'DBIx::Skinny' => 0.05;

author_tests('xt');

build_requires 'Test::More';

use_test_base;
auto_include;
auto_set_repository;
WriteAll;

1;
__END__
