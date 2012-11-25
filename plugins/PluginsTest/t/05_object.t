use strict;
use warnings;

use Test::More tests => 1;
use FindBin qw($Bin);
use lib $Bin;
use MTPath;

use MT;
my $mt = MT->new(Config => test_config) or die MT->errstr;

use MT::Plugins::Test::Object;

subtest 'Common Website' => sub {
    plan tests => 4;

    test_common_website
        test => sub {
            my ( $website, $blog, $author, $password ) = @_;

            ok $website->id;
            ok $blog->id;
            ok $author->id;
            is $password, 'password';
        }
};
