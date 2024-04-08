package PgDbConnection;

use strict;
use warnings;

use DBI;

sub create {
	my $data_source = $ENV{DB_DATA_SOURCE};
	my $username    = $ENV{DB_USERNAME};
	my $password    = $ENV{DB_PASSWORD};

	die 'DB_DATA_SOURCE environment variable is not set' unless defined $data_source;
	die 'DB_USERNAME environment variable is not set'    unless defined $username;
	die 'DB_PASSWORD environment variable is not set'    unless defined $password;

	$data_source = join ':', 'DBI', 'Pg', $data_source;

	my $attr = { PrintError => 0, RaiseError => 0 };
	my $dbh  = DBI->connect( $data_source, $username, $password, $attr );

	die sprintf( 'Can not connect to DB: %s', $DBI::errstr ) unless defined $dbh;

	return $dbh;
}

1;
