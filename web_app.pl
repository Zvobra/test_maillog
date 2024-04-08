#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Mojolicious::Lite;
use PgDbConnection;
use MailLogRepository;

get '/' => sub {
	my ( $c ) = @_;
	$c->render(template => 'default');
};

get '/api/find_by_address' => sub {
	my ( $c ) = @_;
	my $address = $c->param('address');

	unless ( $address ) {
		$c->render( json => {} );
		return;
	}

	my $dbh = PgDbConnection->create;

	my $repository = MailLogRepository->new($dbh);
	my $result = eval {
		$repository->find_by_address(
			address => $address,
			limit   => 100,
			order   => 'DESC',
		)
	};

	$dbh->disconnect;

	$c->render( json => $result || {} );
};

app->start;

1;

