package MT::Plugins::Test::Plugin::SystemConfig;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(test_plugin_system_config);

sub test_plugin_system_config {
    my %args = @_;

    # Validation
    die 'plugin requires.' unless $args{plugin};
    die 'test requires.' unless $args{test};

    # Plugin
    my $plugin = $args{plugin};
    $plugin = MT->component($plugin) unless ref $plugin;
    die 'Unknown plugin: ' . $args{plugin} unless $plugin;

    # Backup current
    my %current_config;
    my $config = $args{config};

    
    $plugin->load_config(\%current_config, 'system');
    $plugin->save_config($config, 'system');

    my $test = $args{test};
    local $@;
    eval {
        $test->($plugin);
    };

    # Restore config.
    $plugin->save_config(\%current_config, 'system');

    # Raise exception
    die $@ if $@;
}

1;
