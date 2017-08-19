package Anego;
use 5.008001;
use strict;
use warnings;
use utf8;

our $VERSION = "0.01_03";

1;

__END__

=encoding utf-8

=head1 NAME

Anego - The database migration utility as our elder sister.

=head1 SYNOPSIS

    # show status
    $ anego status

    # migration
    $ anego migrate
    $ anego migrate revision 1fdc91

    # diff
    $ anego diff
    $ anego diff revision 1fdc91

=head1 WARNING

IT'S STILL IN DEVELOPMENT PHASE.
I have not written document and test script yet.

=head1 DESCRIPTION

Anego is database migration utility.

=head1 CONFIGURATION

    # .anego.pl
    +{
        "connect_info" => ["dbi:mysql:database=myapp;host=localhost", "root"],
        "schema_class" => "MyApp::DB::Schema",
    }

=head1 SCHEMA CLASS

You can declare of the schema using L<DBIx::Schema::DSL>:

    package MyApp::DB::Schema;
    use strict;
    use warnings;
    use DBIx::Schema::DSL;

    create_table 'author' => columns {
        integer 'id', primary_key, auto_increment;
        varchar 'name', unique;
    };

    create_table 'module' => columns {
        integer 'id', primary_key, auto_increment;
        varchar 'name';
        text    'description';
        integer 'author_id';

        add_index 'author_id_idx' => ['author_id'];

        belongs_to 'author';
    };

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

