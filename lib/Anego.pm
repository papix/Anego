package Anego;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Mouse;

use List::UtilsBy qw/ nmax_by /;
use Module::Load;
use Path::Tiny;
use SQL::Translator::Diff;
use SQL::Translator;
use Carp qw/ croak /;

has schema_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has schema_directory => (
    is      => 'ro',
    isa     => 'Str',
    default => '.db',
);

has connect_info => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has master_schema => (
    is         => 'ro',
    isa        => 'SQL::Translator::Schema',
    lazy_build => 1,
);

has database_schema => (
    is         => 'ro',
    isa        => 'SQL::Translator::Schema',
    lazy_build => 1,
);

has rdbms => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my ($self) = @_;
        my $dsn = $self->connect_info->[0];
        return $dsn =~ /:mysql:/ ? 'MySQL'
             : $dsn =~ /:Pg:/    ? 'PostgreSQL'
             : do { my ($d) = $dsn =~ /dbi:(.*?):/; $d };
    },
);

has dbh => (
    is      => 'ro',
    isa     => 'DBI::db',
    default => sub {
        my ($self) = @_;
        return DBI->connect(@{ $self->connect_info });
    },
);

no Mouse;

sub _build_master_schema {
    my ($self) = @_;

    Module::Load::load $self->schema_class;
    return $self->_schema_filter($self->schema_class->context->schema);
}

sub _build_database_schema {
    my ($self) = @_;

    my $schema = SQL::Translator->new(
        parser      => 'DBI',
        parser_args => { dbh => $self->dbh },
    )->translate;
    return $self->_schema_filter($schema);
}

sub build {
    my ($self) = @_;

    my $latest_schema = $self->_load_latest_schema;
    if ($latest_schema) {
        my $diff = $self->_diff($self->master_schema, $latest_schema);
        unless ($diff) {
            print "latest schema == master schema, should no differences.\n";
            return 0;
        }
    }

    Module::Load::load $self->schema_class;
    my $schema_file_name = sprintf('%s.sql', time);
    path($self->schema_directory, $schema_file_name)->spew_utf8($self->schema_class->output);

    printf "create new schema: %s\n", $schema_file_name;
    return 1;
}

sub migrate {
    my $self = shift;
    my $version = shift || 'latest';

    my $target_schema = $version eq 'latest' ? $self->_load_latest_schema : $self->_load_schema($version);
    croak "failed to get schema($version).\n" unless $target_schema;

    my $diff = $self->_diff($self->database_schema, $target_schema);
    unless ($diff) {
        print "target schema ($version) == database schema, should no differences.\n";
        return 0;
    }

    my @statements = map { "$_;"} grep { /\S+/ } split ';', $diff;
    for my $statement (@statements) {
        $self->dbh->do($statement) or croak $self->dbh->errstr;
    }
    return 1;
}

sub diff {
    my $self = shift;
    my $version = shift || 'latest';

    my $target_schema = $version eq 'latest' ? $self->_load_latest_schema : $self->_load_schema($version);
    croak "failed to get schema($version).\n" unless $target_schema;

    my $diff = $self->_diff($self->database_schema, $target_schema);
    unless ($diff) {
        print "target schema ($version) == database schema, should no differences.\n";
        return 0;
    }

    print "target schema ($version) != database schema\n";
    return 0;
}

sub _load_schema {
    my ($self, $version) = @_;

    my $schema_file = path($self->schema_directory, sprintf('%s.sql', $version));
    return $schema_file->is_file
        ? $self->_build_schema_from_ddl($schema_file->slurp_utf8)
        : undef;
}

sub _load_latest_schema {
    my ($self) = @_;

    my @schema_files = path($self->schema_directory)->children;
    return undef if @schema_files == 0;

    my $latest_schema_file = nmax_by { $_ = $_->basename; s/\.sql$// ; $_ } @schema_files;
    return $self->_build_schema_from_ddl($latest_schema_file->slurp_utf8);
}

sub _diff {
    my ($self, $source, $target) = @_;

    my $diff = SQL::Translator::Diff->new({
        output_db     => $self->rdbms,
        source_schema => $source,
        target_schema => $target,
    })->compute_differences->produce_diff_sql;

    return $diff =~ /-- No differences found/ ? undef : $diff;
}

sub _build_schema_from_ddl {
    my ($self, $ddl) = @_;

    my $schema = SQL::Translator->new(
        parser => $self->rdbms,
        data   => \$ddl
    )->translate;
    return $self->_schema_filter($schema);
}

sub _schema_filter {
    my ($self, $schema) = @_;

    if ($self->rdbms eq 'MySQL') {
        for my $table ($schema->get_tables) {
            my @options = $table->options;
            if (my ($idx) = grep { $options[$_]->{AUTO_INCREMENT} } 0..$#options) {
                no warnings;
                splice $table->options, $idx, 1;
            }
            for my $field ($table->get_fields) {
                delete $field->{default_value} if $field->{is_nullable} && exists $field->{default_value} && $field->{default_value} eq 'NULL';
            }
        }
    }
    return $schema;
}

1;
__END__

=encoding utf-8

=head1 NAME

Anego - The database migration utility as our elder sister.

=head1 SYNOPSIS

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

=head1 WARNING

IT'S STILL IN DEVELOPMENT PHASE.
I have not written document and test script yet.

=head1 DESCRIPTION

Anego is database migration utility.

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

