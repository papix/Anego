# NAME

Anego - The database migration utility as our elder sister.

# SYNOPSIS

    package MyApp::Schema {
        use DBIx::Schema::DSL;

        create_table 'user' => columns {
            integer 'id', primary_key, auto_increment;
            varchar 'name';
        };
    };

    package main {
        use Anego;

        my $anego = Anego->new(
            connect_info => [ ... ],
            schema_class => 'MyApp::Schema',
        );

        # create schema file into '.db'
        $anego->build;

        # display differences between database schema and latest schema
        $anego->diff;

        # migrate database
        $anego->migrate;
    };

    1;

# WARNING

IT'S STILL IN DEVELOPMENT PHASE.
I have not written document and test script yet.

# DESCRIPTION

Anego is database migration utility.

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>
