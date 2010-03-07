package Mock::BasicPg;
use DBIx::Skinny setup => +{};
use DBIx::Skinny::Plus::NestedTransaction;

my $table = 'mock_basic_pg';
sub setup_test_db {
    my $class = shift;
    eval { $class->do(qq{
        DROP TABLE $table
    }) };
    $class->do(qq{
        CREATE TABLE $table (
            id   SERIAL PRIMARY KEY,
            name TEXT
        )
    });
}

sub cleanup_test_db {
    shift->do(qq{DROP TABLE $table});
}

1;

