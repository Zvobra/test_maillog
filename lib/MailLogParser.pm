package MailLogParser;

use strict;
use warnings;

use Readonly;

Readonly::Scalar my $MESSAGE_FLAGS => {
	INCOMING               => '<=',
	OUTGOING               => '=>',
	OUTGOING_EXTRA_ADDRESS => '->',
	OUTGOING_ERROR         => '**',
	OUTGOING_DELAYED       => '==',
};

Readonly::Scalar my $MESSAGE_FLAGS_RE => join '|', map { quotemeta $_ } values %$MESSAGE_FLAGS;

sub new {
	my ( $class ) = @_;

	my $self = {
		_incoming_message_handler => undef,
		_log_handler              => undef,
	};

	return bless $self, $class;
}

sub on_incoming_message {
	my ( $self, $handler ) = @_;

	die 'handler must be CODE' unless ref $handler eq 'CODE';

	$self->{_incoming_message_handler} = $handler;

	return $self;
}

sub on_log {
	my ( $self, $handler ) = @_;

	die 'handler must be CODE' unless ref $handler eq 'CODE';

	$self->{_log_handler} = $handler;

	return $self;
}

sub read_log {
	my ( $self, $log ) = @_;

	die 'log is not provided' unless defined $log;
	die 'log must be scalar'  unless ref $log eq '';

	my $log_entry = $self->_parse_raw_log($log);

	return unless defined $log_entry;

	if ( $log_entry->{flag} eq $MESSAGE_FLAGS->{INCOMING} ) {
		return $self->_parse_incoming_message($log_entry);
	}

	return $self->_parse_log($log_entry);
}

sub _parse_raw_log {
	my ( undef, $log ) = @_;

	return unless $log =~ m{
		^
		\s* (?<date> \d{4}-\d{2}-\d{2} )
		\s+ (?<time> \d{2}:\d{2}:\d{2} )
		(?: \s+ (?<int_id> [[:alnum:]]{6}-[[:alnum:]]{6}-[[:alnum:]]{2} ) )?
		(?: \s+ (?<flag> $MESSAGE_FLAGS_RE ) )?
		(?: \s+ (?<body> .* ) )?
		$
	}x;

	my %log_entry = map { +$_ => $+{ $_ } || '' } (
		'int_id',
		'flag',
		'body',
	);

	$log_entry{timestamp} = join ' ', $+{date}, $+{time};

	return { %log_entry, raw => $log };
}

sub _parse_incoming_message {
	my ( $self, $log_entry ) = @_;

	my $handler = $self->{_incoming_message_handler};
	return 1 unless defined $handler;

	my ( $id ) = $log_entry->{body} =~ m/\sid=(\S+)/;
	$id ||= '';

	return $handler->(
		created => $log_entry->{timestamp},
		id      => $id,
		int_id  => $log_entry->{int_id},
		str     => $self->_get_log_without_timestamp($log_entry),
	);
}

sub _parse_log {
	my ( $self, $log_entry ) = @_;

	my $handler = $self->{_log_handler};
	return 1 unless defined $handler;

	my $address = '';
	if ( $log_entry->{flag} ne '' ) {
		# Доверяем формату лога и не проверяем корректность адреса
		( $address ) = $log_entry->{body} =~ m/^(?: :blackhole:\s* )? [<:]* ( [^>:\s]+ )/x;
		$address ||= '';
	}

	return $handler->(
		created => $log_entry->{timestamp},
		int_id  => $log_entry->{int_id},
		str     => $self->_get_log_without_timestamp($log_entry),
		address => $address,
	);
}

sub _get_log_without_timestamp {
	my ( undef, $log_entry ) = @_;

	return join ' ', map { $_ || () } (
		$log_entry->{int_id},
		$log_entry->{flag},
		$log_entry->{body},
	);
}

1;
