package MT::Plugins::Test::Path;

use strict;
use warnings;
use base qw(MT::Plugins::Test Exporter);

our @EXPORT = qw/dummy_site_path dummy_site_url dummy_site_path_and_url/;

use File::Spec;
use File::Path qw/rmtree mkpath/;

sub dummy_site_path {
    my $path = File::Spec->catdir(MT->instance->support_directory_path, 'dummy', @_);
    rmtree $path if -d $path;
    mkpath $path;
    $path;
}

sub dummy_site_url {
    require MT::Util;
    my $url = MT::Util::caturl(MT->instance->support_directory_url, 'dummy', @_);
    $url;
}

sub remove_dummy_tree {
    my $path = dummy_site_path;
    rmtree $path if -d $path;
    $path;
}

sub dummy_site_path_and_url {
    my $path = dummy_site_path(@_);
    my $url = dummy_site_url(@_);

    (
        site_path => $path,
        site_url => $url,
    );
}

1;
