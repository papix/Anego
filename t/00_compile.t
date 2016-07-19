use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Anego
    Anego::CLI
    Anego::CLI::Migrate
    Anego::CLI::Status
    Anego::CLI::Version
    Anego::Config
    Anego::Git
    Anego::Logger
    Anego::Task::Diff
    Anego::Task::GitLog
    Anego::Task::SchemaLoader
    Anego::Util
);

done_testing;

