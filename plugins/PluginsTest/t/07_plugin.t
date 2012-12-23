use strict;
use warnings;

use Test::More tests => 1;
use FindBin qw($Bin);
use lib $Bin;
use MTPath;

use MT;
my $mt = MT->new(Config => test_config) or die MT->errstr;

use MT::Plugins::Test::Plugin::SystemConfig;

subtest 'Plugin System Config' => sub {
    plan tests => 3;

    my $plugin = MT->component('pluginstest');

    # Reset config and resave
    my %config;
    $plugin->reset_config();
    $plugin->load_config(\%config, 'system');
    $plugin->save_config(\%config, 'system');

    # Initial
    is_deeply \%config, {
        config1 => 'config-1',
        'config1_config-1' => 1,
    }, 'Initial config state';

    my $local_config = {
        config1 => 'CONFIG-1',
        'config1_CONFIG-1' => 1,
        config2 => 'CONFIG-2',
        'config2_CONFIG-2' => 1,
    };
    test_plugin_system_config(
        plugin => 'pluginstest',
        config => $local_config,
        test => sub {
            my $p = shift;
            my %temp;
            $p->load_config(\%temp, 'system');
            is_deeply \%temp, $local_config, 'Temporary config state';
        },
    );

    is_deeply \%config, {
        config1 => 'config-1',
        'config1_config-1' => 1,
    }, 'Restored config state';

};

