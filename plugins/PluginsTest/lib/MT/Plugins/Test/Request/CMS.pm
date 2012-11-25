package MT::Plugins::Test::Request::CMS;

use strict;
use warnings;
use base qw(MT::Plugins::Test::Request);

use MT;

sub app_class { 'MT::App::CMS' }
sub cgi_file { 'mt.cgi' }

sub cgi_path {
    my $pkg = shift;
    my $config = MT->instance->config;
    $config->AdminCGIPath || $config->CGIPath;
}

sub cgi_dir_path {
    my $self = shift;

    my $config = MT->instance->config;
    my $path = $config->AdminCGIDirPath || $config->CGIDirPath || return;
    return unless -d $path;

    $path;
}

sub signin_default { 1 }

1;
