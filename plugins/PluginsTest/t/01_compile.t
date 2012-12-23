use strict;
use warnings;

use Test::More tests => 5;
use FindBin qw($Bin);
use lib $Bin;
use MTPath;

use MT;
my $mt = MT->new(Config => test_config) or die MT->errstr;

use_ok 'MT::Plugins::Test';
use_ok 'MT::Plugins::Test::Object';
use_ok 'MT::Plugins::Test::Path';
use_ok 'MT::Plugins::Test::Request';
use_ok 'MT::Plugins::Test::Plugin::SystemConfig';
