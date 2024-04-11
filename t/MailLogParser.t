#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 5;

use MailLogParser;

sub _create_parser {
	return MailLogParser->new;
}

ok _create_parser->isa('MailLogParser'), 'Создание объекта MailLogParser';

subtest 'неверные входные данные - dies' => sub {
	my @test_data = (
		undef,
		{},
		[],
		sub {},
	);

	plan tests => scalar @test_data;

	foreach my $i ( 0 .. $#test_data ) {
		my $log = $test_data[ $i ];
		ok !eval { _create_parser->read_log($log); 1; }, "Data index: $i";
	}
};

subtest 'неверный формат лога - возвращает false' => sub {
	my @test_data = (
		'',
		'1RwtJb-000Ab2-9u => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router',
		'2012-02-13 1RwtJb-000Ab2-9u => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router',
		'14:39:23 1RwtJb-000Ab2-9u => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router',
	);

	plan tests => scalar @test_data;

	foreach my $i ( 0 .. $#test_data ) {
		my $log = $test_data[ $i ];
		ok !_create_parser->read_log($log), "Строка лога #$i: $log";
	}
};

subtest 'on_log - верный формат лога' => sub {
	my @test_data = (
		{
			log      => '2012-02-13 14:39:22 1RwtJa-000AFB-07 => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '1RwtJa-000AFB-07',
				str     => '1RwtJa-000AFB-07 => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router',
				address => 'tpxmuwr@somehost.ru',
			},
		},
		{
			log      => '2012-02-13 14:39:22 1RwtJa-000AFB-07 ** fwxvparobkymnbyemevz@london.com: retry timeout exceeded',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '1RwtJa-000AFB-07',
				str     => '1RwtJa-000AFB-07 ** fwxvparobkymnbyemevz@london.com: retry timeout exceeded',
				address => 'fwxvparobkymnbyemevz@london.com',
			},
		},
		{
			log      => '2012-02-13 14:39:22 1RwtJa-000AFB-07 ** <fwxvparobkymnbyemevz@london.com>: retry timeout exceeded',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '1RwtJa-000AFB-07',
				str     => '1RwtJa-000AFB-07 ** <fwxvparobkymnbyemevz@london.com>: retry timeout exceeded',
				address => 'fwxvparobkymnbyemevz@london.com',
			},
		},
		{
			log      => '2012-02-13 14:39:22 1RwtJa-000AFB-07 Completed',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '1RwtJa-000AFB-07',
				str     => '1RwtJa-000AFB-07 Completed',
				address => '',
			},
		},
		{
			log      => '2012-02-13 14:39:22 1RwtJa-000AFB-07',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '1RwtJa-000AFB-07',
				str     => '1RwtJa-000AFB-07',
				address => '',
			},
		},
		{
			log      => '2012-02-13 14:39:22 1RwtJa-000-AFB-07',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '',
				str     => '1RwtJa-000-AFB-07',
				address => '',
			},
		},
		{
			log      => '2012-02-13 14:39:22 Error',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '',
				str     => 'Error',
				address => '',
			},
		},
		{
			log      => '2012-02-13 14:39:22',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '',
				str     => '',
				address => '',
			},
		},
		{
			log      => '2012-02-13  14:39:22',
			expected => {
				created => '2012-02-13 14:39:22',
				int_id  => '',
				str     => '',
				address => '',
			},
		},
	);

	plan tests => scalar @test_data;

	foreach my $i ( 0 .. $#test_data ) {
		my $data = $test_data[ $i ];

		my $parser = _create_parser;
		my %result;

		$parser->on_log( sub {
			%result = @_;
		});

		$parser->read_log( $data->{log} );

		is_deeply \%result, $data->{expected}, "Data #$i";
	}
};

subtest 'on_incoming_message - верный формат лога' => sub {
	my @test_data = (
		{
			log      => '2012-02-13 14:39:24 1RwtJc-0009RI-I5 <= tpxmuwr@somehost.ru H=mail.somehost.com [84.154.134.45] P=esmtp S=1260 id=120213143602.COM_FM_END.73812@whois.somehost.ru',
			expected => {
				created => '2012-02-13 14:39:24',
				int_id  => '1RwtJc-0009RI-I5',
				str     => '1RwtJc-0009RI-I5 <= tpxmuwr@somehost.ru H=mail.somehost.com [84.154.134.45] P=esmtp S=1260 id=120213143602.COM_FM_END.73812@whois.somehost.ru',
				id      => '120213143602.COM_FM_END.73812@whois.somehost.ru',
			},
		},
		{
			log      => '2012-02-13 14:39:24 1RwtJc-0009RI-I5 <= <> R=1RlJ2m-000J0n-Dd U=mailnull P=local S=2319',
			expected => {
				created => '2012-02-13 14:39:24',
				int_id  => '1RwtJc-0009RI-I5',
				str     => '1RwtJc-0009RI-I5 <= <> R=1RlJ2m-000J0n-Dd U=mailnull P=local S=2319',
				id      => '',
			},
		},
	);

	plan tests => scalar @test_data;

	foreach my $i ( 0 .. $#test_data ) {
		my $data = $test_data[ $i ];

		my $parser = _create_parser;
		my %result;

		$parser->on_incoming_message( sub {
			%result = @_;
		});

		$parser->read_log( $data->{log} );

		is_deeply \%result, $data->{expected}, "Data #$i";
	}
};
