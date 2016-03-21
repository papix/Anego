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

no Mouse;

sub _build_master_schema {
    my ($self) = @_;

    Module::Load::load $self->schema_class;
    return $self->_schema_filter($self->schema_class->context->schema);
}

sub build {
    my ($self) = @_;

    my @schema_files = path($self->schema_directory)->children;
    if (@schema_files) {
        my $latest_schema_file = nmax_by { s/\.sql$// } @schema_files;
        my $latest_schema = $self->_build_schema_from_ddl($latest_schema_file->slurp_utf8);

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
        }
    }
    return $schema;
}

1;
__END__

=encoding utf-8

=head1 NAME

Anego - It's new $module

=head1 SYNOPSIS

    use Anego;

=head1 DESCRIPTION

Anego is ...

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

