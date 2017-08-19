package Anego::Task::SchemaLoader;
use strict;
use warnings;
use utf8;
use Digest::MD5 qw/ md5_hex /;
use Module::Load;
use SQL::Translator;

use Anego::Config;
use Anego::Git;

sub from {
    my $class  = shift;
    my $method = lc(shift || 'latest');
    my @args   = @_;

    unless ($class->can($method)) {
        errorf("Could not use method: %s\n", $method);
    }

    return $class->$method(@args);
}

sub revision {
    my ($class, $revision) = @_;
    my $config = Anego::Config->load;

    my $schema_class = $config->schema_class;
    my $schema_str   = git_cat_file(sprintf('%s:%s', $revision, $config->schema_path));
    $schema_str =~ s/package\s+$schema_class;?//;

    my $klass = sprintf('Anego::__ANON__::%s::%s', $revision, md5_hex(int rand 65535));
    eval sprintf <<'__SRC__', $klass, $schema_str;
package %s {
    %s
}
__SRC__

    my $schema = SQL::Translator->new(
        parser => $config->rdbms,
        data   => \$klass->output,
    )->translate;
    return _filter($schema);
}

sub latest {
    my ($class) = @_;
    my $config = Anego::Config->load;

    my $schema_class = $config->schema_class;
    Module::Load::load $schema_class;

    my $schema = SQL::Translator->new(
        parser => $config->rdbms,
        data   => \$schema_class->output,
    )->translate;
    return _filter($schema);
}

sub database {
    my ($class) = @_;
    my $config = Anego::Config->load;

    my $schema = SQL::Translator->new(
        parser      => 'DBI',
        parser_args => { dbh => $config->dbh },
    )->translate;
    return _filter($schema);
}

sub _filter {
    my ($schema) = @_;
    my $config = Anego::Config->load;

    if ($config->rdbms eq 'MySQL') {
        for my $table ($schema->get_tables) {
            my $options = $table->options;
            if (my ($idx) = grep { $options->[$_]->{AUTO_INCREMENT} } 0..$#{$options}) {
                splice @{ $options }, $idx, 1;
            }
            for my $field ($table->get_fields) {
                delete $field->{default_value} if $field->{is_nullable} && exists $field->{default_value} && $field->{default_value} eq 'NULL';
            }
        }
    }
    return $schema;
}

1;
