package SelfTest;

use strict;
use warnings;

use base 'Exporter';

use Test::More;
use MTPath;
use JSON;

use MT::Plugins::Test::Request::CMS;
my $cms = 'MT::Plugins::Test::Request::CMS';
my $via = 'bootstrap';

sub import {
    my $pkg = shift;
    my %param = @_;
    $via = $param{via} if $param{via};
}

sub run {
    shift;

    plan tests => 2;

    subtest 'Before Signin' => \&before_signin;
    subtest 'After Signin' => \&after_signin;
}

sub before_signin {
    plan tests => 1;

    note $via;

    $cms->test_mech(
        via => $via,
        test => sub {
            my $mech = shift;
            my $res = $mech->get($cms->uri( __mode => 'plugins_test_self_test' ));

            like $res->content, qr!<body\s(.*?)id="sign-in"!s;
        },
    );
};

sub after_signin {
    plan tests => 4;

    note $via;

    $cms->test_user_mech(
        as_superuser => 1,
        via => $via,
        test => sub {
            my $mech = shift;

            my $res = $mech->get($cms->uri( __mode => 'plugins_test_self_test' ));

            is $res->headers->header('Plugins-Log-Count'), 2;
            is $res->headers->header('Plugins-Log-0000'), 'First Message';
            is $res->headers->header('Plugins-Log-0001'), 'Second Message';

            my $json = eval { from_json($res->content); };

            is_deeply $json, {
                error => undef,
                result => { test => 'OK' },
            };
        },
    );
}

1;
