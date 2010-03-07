package Mock::BasicMySQL;
use DBIx::Skinny setup => +{};

my $table = 'mock_basic_mysql';
sub setup_test_db {
    my $class = shift;
    $class->do(qq{
        DROP TABLE IF EXISTS $table
    });
    $class->do(qq{
        CREATE TABLE $table (
            id   INT auto_increment,
            name TEXT,
            PRIMARY KEY  (id)
        ) ENGINE=InnoDB
    });
}
use DBIx::Skinny::Plus::NestedTransaction;

sub cleanup_test_db {
    shift->do(qq{DROP TABLE $table});
}

1;

