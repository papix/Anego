[![Build Status](https://travis-ci.org/papix/Anego.svg?branch=master)](https://travis-ci.org/papix/Anego)
# NAME

Anego - The database migration utility as our elder sister.

# SYNOPSIS

    # show status
    $ anego status

    # migration
    $ anego migrate
    $ anego migrate revision 1fdc91

    # diff
    $ anego diff
    $ anego diff revision 1fdc91

# WARNING

IT'S STILL IN DEVELOPMENT PHASE.
I have not written document and test script yet.

# DESCRIPTION

Anego is database migration utility.

# CONFIGURATION

    # .anego.pl
    +{
        "connect_info" => ["dbi:mysql:database=myapp;host=localhost", "root"],
        "schema_class" => "MyApp::DB::Schema",
    }

# SCHEMA CLASS

You can declare of the schema using [DBIx::Schema::DSL](https://metacpan.org/pod/DBIx::Schema::DSL):

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

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>
