package Anego::CLI::Migrate;
use strict;
use warnings;
use utf8;

use Anego::Config;
use Anego::Logger;
use Anego::Task::Diff;
use Anego::Task::GitLog;
use Anego::Task::SchemaLoader;
use Anego::Util;

sub run {
    my ($class, @args) = @_;
    my $config = Anego::Config->load;

    my $source_schema = Anego::Task::SchemaLoader->database;
    my $target_schema;

    my $subcommand = shift @args || 'latest';
    if ($subcommand eq 'latest') {
        $target_schema = Anego::Task::SchemaLoader->master;
    } elsif ($subcommand eq 'revision') {
        my $revision = shift @args or errorf("Missing target revision");
        $target_schema = Anego::Task::SchemaLoader->git($revision);
    } else {
        errorf("Could not find subcommand: %s\n", $subcommand);
    }

    my $diff = Anego::Task::Diff->diff($source_schema, $target_schema);
    unless ($diff) {
        warnf("target schema == database schema, should no differences\n");
        return;
    }

    do_sql($diff);

    infof "Migrated\n";
}

1;
