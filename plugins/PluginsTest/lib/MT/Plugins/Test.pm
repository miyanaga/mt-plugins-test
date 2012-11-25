package MT::Plugins::Test;

use strict;
use warnings;
use base 'Exporter';
use MT;

our @EXPORT = qw(test_plugin plugins_log request);

sub test_plugin {
    MT->component('pluginstest');
}

sub error {
    my $pkg = shift;
    my $msg = shift;
    print STDERR $msg, "\n";
    return;
}

sub plugins_log {
    my $msg = shift;
    MT->instance->{cgi_headers}{'PLUGINS-LOG-COUNT'} ||= 0;
    my $index = sprintf('%04d', MT->instance->{cgi_headers}{'PLUGINS-LOG-COUNT'}++);
    MT->instance->{cgi_headers}{"PLUGINS-LOG-$index"} ||= '';
    MT->instance->{cgi_headers}{"PLUGINS-LOG-$index"} .= $msg;
}

sub self_test_handler {
    my $app = shift;

    plugins_log('First Message');
    plugins_log('Second Message');

    $app->json_result({
        test => 'OK'
    });
}

1;
