package MailLogRepository;

use strict;
use warnings;

use constant {
	TABLE_LOG          => 'log',
	TABLE_MESSAGE      => 'message',
	DEFAULT_FIND_LIMIT => 100,
};

sub new {
	my ( $class, $dbh ) = @_;

	die 'dbh is not provided' unless defined $dbh;

	my $self = {
		_dbh => $dbh,
	};

	return bless $self, $class;
}

sub add_log {
	my ( $self, %params ) = @_;

	my $created = $params{created} or die 'created is not provided';
	my $int_id  = $params{int_id}  || '';
	my $str     = $params{str}     || '';
	my $address = $params{address} || '';

	my $t = TABLE_LOG;

	my $result = $self->{_dbh}->do(
		qq{INSERT INTO $t (created, int_id, str, address) VALUES (?, ?, ?, ?)},
		undef,
		$created, $int_id, $str, $address,
	);

	die sprintf( 'Error occurred: %s', $self->{_dbh}->errstr ) unless defined $result;

	return $result;
}

sub add_message {
	my ( $self, %params ) = @_;

	my $created = $params{created} or die 'created is not provided';
	my $id      = $params{id}      or die 'id is not provided';
	my $int_id  = $params{int_id}  || '';
	my $str     = $params{str}     || '';

	my $t = TABLE_MESSAGE;

	my $result = $self->{_dbh}->do(
		qq{INSERT INTO $t (created, int_id, str, id) VALUES (?, ?, ?, ?)},
		undef,
		$created, $int_id, $str, $id,
	);

	die sprintf( 'Error occurred: %s', $self->{_dbh}->errstr ) unless defined $result;

	return $result;
}

sub find_by_address {
	my ( $self, %params ) = @_;

	my $address = $params{address} or die 'address is not provided';

	my $limit   = $params{limit} ? int($params{limit}) : DEFAULT_FIND_LIMIT;
	die 'limit must be greater than 0' if $limit <= 0;

	my $order   = $params{order} || 'ASC';
	die 'order can be ASC or DESC' unless grep { $order eq $_ } qw ( ASC DESC );

	my $t_log     = TABLE_LOG;
	my $t_message = TABLE_MESSAGE;

	my $limit_plus_one = $limit + 1;

	my $result = $self->{_dbh}->selectall_arrayref(
		qq{
			WITH log_data AS (
				SELECT int_id, created, str
				FROM $t_log
				WHERE address = ?
			)
			SELECT int_id, created, str
			FROM $t_message
			WHERE int_id IN ( SELECT int_id FROM log_data )
			UNION
			SELECT *
			FROM log_data
			ORDER BY int_id $order, created $order
			LIMIT $limit_plus_one
		},
		{ Slice => {} },
		$address,
	);

	die sprintf( 'Error occurred: %s', $self->{_dbh}->errstr ) unless defined $result;

	my $limit_exceeded = 0;
	if ( $limit < scalar @$result ) {
		$limit_exceeded = 1;
		pop @$result;
	}

	return {
		result         => $result,
		limit_exceeded => $limit_exceeded,
	};
}

1;
