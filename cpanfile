requires 'DBI';
requires 'DBIx::Schema::DSL';
requires 'Digest::MD5';
requires 'Exporter';
requires 'File::Spec';
requires 'Getopt::Long';
requires 'Git::Repository';
requires 'Module::Load';
requires 'SQL::Translator';
requires 'Term::ANSIColor';
requires 'Try::Tiny';
requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
