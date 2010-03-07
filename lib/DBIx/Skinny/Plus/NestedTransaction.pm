package DBIx::Skinny::Plus::NestedTransaction;

use strict;
use warnings;
use Carp ();

our $VERSION = '0.01';


sub import {
    my $caller = caller;

    my @functions = qw( txn_scope txn_begin txn_rollback txn_commit txn_end );

    no warnings;
    no strict 'refs';

    for my $func (@functions) {
        *{"$caller\::$func"} = \&$func;
    }

}


BEGIN {

    sub txn_scope {
        DBIx::Skinny::Transaction->new( @_ );
    }


    sub txn_begin {
        my $class = shift;
        return if ( ++$class->attribute->{active_transaction} > 1 );
        $class->profiler("BEGIN WORK");
        eval { $class->dbh->begin_work } or Carp::croak $@;
    }


    sub txn_rollback {
        my $class = shift;
        return unless $class->attribute->{active_transaction};

        if ( $class->attribute->{active_transaction} == 1 ) {
            $class->profiler("ROLLBACK WORK");
            eval { $class->dbh->rollback } or Carp::croak $@;
            $class->txn_end;
        }
        elsif ( $class->attribute->{active_transaction} > 1 ) {
            $class->attribute->{active_transaction}--;
            $class->attribute->{rollbacked_in_nested_transaction}++;
        }

    }


    sub txn_commit {
        my $class = shift;
        return unless $class->attribute->{active_transaction};

        if ( $class->attribute->{rollbacked_in_nested_transaction} ) {
            Carp::croak "tried to commit but alreay rollbacked in nested transaction.";
        }
        elsif ( $class->attribute->{active_transaction} > 1 ) {
            $class->attribute->{active_transaction}--;
            return;
        }

        $class->profiler("COMMI WORK");
        eval { $class->dbh->commit } or Carp::croak $@;
        $class->txn_end;
    }


    sub txn_end {
        $_[0]->attribute->{active_transaction} = 0;
        $_[0]->attribute->{rollbacked_in_nested_transaction} = 0;
    }

}


1;
__END__

=pod

=head1 NAME

DBIx::Skinnyy::Plus::NestedTransaction - deal with nested transaction

=head1 SYNOPSIS

    #
    package Your::Model;
    use DBIx::Skinny setup => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
        connect_options => { AutoCommit => 1 },
    };
    use DBIx::Skinny::Plus::NestedTransaction;
    
    package main;
    
    use Your::Model;
    
    my $txn   = Your::Model->txn_scope;
    {
        my $txn2 = Your::Model->txn_scope;
        eval q{ Your::Model->insert('a_table',{ name => 'foo' }) };
        if ( $@ ) {
            $txn2->rollback;
        }
        else {
            $txn2->commit;
        }
    }
    eval q{ Your::Model->insert('some_table',{ name => 'bar' }) };
    
    $txn->commit unless $@;

=head1 DESCRIPTION

L<DBIx::Skinny> does not deal with nested transaction.

Using this module enable you to do it.

Use this module after C<use DBIx::Skinny> in your model class.


=head1 ADDITIONAL

C<txn_begin>, C<txn_commit>, C<txn_rollback> methods call C<profiler> for logging SQL statements.

=head1 SEE ALSO

L<DBIx::Skinny>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 


=cut

