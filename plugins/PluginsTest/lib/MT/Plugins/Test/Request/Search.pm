package MT::Plugins::Test::Request::Search;

use strict;
use warnings;
use base qw(MT::Plugins::Test::Request);

use MT;

sub app_class { 'MT::App::Search' }
sub cgi_file { 'mt-search.cgi' }

1;
