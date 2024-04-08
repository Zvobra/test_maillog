#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use feature qw( say );

use MailLogParser;
use MailLogRepository;
use PgDbConnection;

my $log_file = $ARGV[0] or die 'log file is not provided';
die 'log file does not exists' unless -e $log_file;

my $dbh = PgDbConnection->create;

my $repository = MailLogRepository->new($dbh);

my $parser = MailLogParser->new();
$parser->on_log( sub { eval { $repository->add_log(@_) } } );
$parser->on_incoming_message( sub {
	my %params = @_;
	# Т.к. id обязателен в таблице, пропускаю входящие сообщения без него
	# (не знаю, что с ними делать)
	return if $params{id} eq '';
	eval { $repository->add_message(@_) };
});

open my $fh, '<', $log_file or die "Can not read log file: $!";

say 'import started';

my $lines_count           = 0;
my $processed_lines_count = 0;
while ( my $log = readline $fh ) {
	++$lines_count;
	my $parse_result = $parser->read_log($log);
	++$processed_lines_count if $parse_result;
}

say sprintf (
	'import finished, successfully processed %s of %s lines',
	$processed_lines_count,
	$lines_count,
);

close $fh;

$dbh->disconnect;

1;
