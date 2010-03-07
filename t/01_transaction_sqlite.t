use strict;
use warnings;
use utf8;
use Test::More;
use lib './t';
use Mock::Basic;

Mock::Basic->setup_test_db;

subtest 'do basic transaction' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 1;
    is $row->name, 'perl';
    Mock::Basic->txn_commit;

    is +Mock::Basic->single('mock_basic',{id => 1})->name, 'perl';
    done_testing;
};
 
subtest 'do rollback' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    Mock::Basic->txn_rollback;
    
    ok not +Mock::Basic->single('mock_basic',{id => 2});
    done_testing;
};
 
subtest 'do commit' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    Mock::Basic->txn_commit;
 
    ok +Mock::Basic->single('mock_basic',{id => 2});
    done_testing;
};
 
subtest 'do scope commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 3;
    is $row->name, 'perl';
    $txn->commit;
 
    ok +Mock::Basic->single('mock_basic',{id => 3});
    done_testing;
};
 
subtest 'do scope rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 4;
    is $row->name, 'perl';
    $txn->rollback;
 
    ok not +Mock::Basic->single('mock_basic',{id => 4});
    done_testing;
};
 
subtest 'do scope guard for rollback' => sub {
 
    {
        my $txn = Mock::Basic->txn_scope;
        my $row = Mock::Basic->insert('mock_basic',{
            name => 'perl',
        });
        is $row->id, 4;
        is $row->name, 'perl';
    }
 
    ok not +Mock::Basic->single('mock_basic',{id => 4});
    done_testing;
};


subtest 'do nested scope rollback-rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 4;
        is $row2->name, 'perl5.10';
        $txn2->rollback;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 5;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 4});
    ok not +Mock::Basic->single('mock_basic',{id => 5});
    done_testing;
};

subtest 'do nested scope commit-rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 4;
        is $row2->name, 'perl5.10';
        $txn2->commit;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 5;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 4});
    ok not +Mock::Basic->single('mock_basic',{id => 5});
    done_testing;
};

subtest 'do nested scope rollback-commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 4;
        is $row2->name, 'perl5.10';
        $txn2->rollback;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 5;
    is $row->name, 'perl5.12';

    eval { $txn->commit };

    like( $@, qr/tried to commit but alreay rollbacked in nested transaction./, "error message" );

    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 4});
    ok not +Mock::Basic->single('mock_basic',{id => 5});
    done_testing;
};

subtest 'do nested scope commit-commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 4;
        is $row2->name, 'perl5.10';
        $txn2->commit;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 5;
    is $row->name, 'perl5.12';
    $txn->commit;

    ok +Mock::Basic->single('mock_basic',{id => 4});
    ok +Mock::Basic->single('mock_basic',{id => 5});
    done_testing;
};

subtest 'do nested scope rollback-commit-rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 6;
        is $row2->name, 'perl5.10';

        {
            my $txn3 = Mock::Basic->txn_scope;
            my $row3 = Mock::Basic->insert('mock_basic',{
                name => 'perl',
            });
            is $row3->id, 7;
            is $row3->name, 'perl';
        }

        eval { $txn2->commit };
        like( $@, qr/tried to commit but alreay rollbacked in nested transaction./, "error message" );
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 8;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 6});
    ok not +Mock::Basic->single('mock_basic',{id => 7});
    ok not +Mock::Basic->single('mock_basic',{id => 8});
    done_testing;
};


subtest 'do nested scope rollback-commit-commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 6;
        is $row2->name, 'perl5.10';

        {
            my $txn3 = Mock::Basic->txn_scope;
            my $row3 = Mock::Basic->insert('mock_basic',{
                name => 'perl',
            });
            is $row3->id, 7;
            is $row3->name, 'perl';
        }
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 8;
    is $row->name, 'perl5.12';

    eval { $txn->commit };
    like( $@, qr/tried to commit but alreay rollbacked in nested transaction./, "error message" );
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 6});
    ok not +Mock::Basic->single('mock_basic',{id => 7});
    ok not +Mock::Basic->single('mock_basic',{id => 8});
    done_testing;
};


done_testing;


