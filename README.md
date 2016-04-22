# NAME

Anego - The database migration utility as our elder sister.

# SYNOPSIS

    $ anego migrate
    $ anego migrate revision 1fdc91
    $ anego status

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

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>
