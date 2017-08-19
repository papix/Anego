use strict;
use warnings;
use Test::More;
use Test::Git;
use Test::Requires::Git;

use Capture::Tiny qw/ capture /;
use Path::Tiny;

use Anego::CLI::Diff;
use Anego::CLI::Migrate;
use Anego::CLI::Status;

eval 'use DBD::SQLite';
if ($@) {
    plan skip_all => 'DBD::SQLite is required';
}

test_requires_git;

my $repo = test_repository;
chdir $repo->work_tree;
path($repo->work_tree, qw/ lib MyApp /)->mkpath;

$repo->run(qw/ config --local user.name papix /);
$repo->run(qw/ config --local user.email mail@papix.net /);

my $schema = <<__SCHEMA__;
package MyApp::Schema;
use strict;
use warnings;
use utf8;

use DBIx::Schema::DSL;

database 'MySQL';
add_table_options
    'mysql_table_type' => 'InnoDB',
    'mysql_charset'    => 'utf8mb4';

create_table user => columns {
    integer 'id'   => not_null, unsigned, primary_key;
    varchar 'name' => not_null;

    datetime 'created_at' => not_null;
    datetime 'updated_at' => not_null;
};

1;
__SCHEMA__

my $schema_file = path($repo->work_tree, qw/ lib MyApp Schema.pm /);
$schema_file->spew_utf8($schema);

my $config = <<__CONFIG__;
{
    connect_info => ['dbi:SQLite:dbname=:memory:', '', ''],
    schema_class => 'MyApp::Schema',
}
__CONFIG__

my $config_file = path($repo->work_tree, qw/ .anego.pl /);
$config_file->spew_utf8($config);

$repo->run('add', $schema_file);
$repo->run('commit', '-m', 'initial commit');

subtest 'status subcommand' => sub {
    my ($stdout, $stderr) = capture {
        Anego::CLI::Status->run();
    };

    like $stdout, qr!RDBMS:\s+SQLite!;
    like $stdout, qr!Database:\s+:memory:!;
    like $stdout, qr!Schema class:\s+MyApp::Schema\s+\(lib/MyApp/Schema\.pm\)!;
};

done_testing;
