package MT::Plugins::Test::Request;

use strict;
use warnings;
use base qw(MT::Plugins::Test);

our $DEFAULT_NAME = 'tester';
our $DEFAULT_PASSWORD = 'password';
our $DEFAULT_TIMEOUT = 30;
our $DEFAULT_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:16.0) Gecko/20100101 Firefox/16.0';

use WWW::Mechanize;
use WWW::Mechanize::CGI;

use MT;
require MT::Bootstrap;
use MT::Util qw(caturl encode_url);
use MT::Plugins::Test::Object;
use File::Spec;
use Test::More;

our @VIA = qw/bootstrap http process/;

sub app_class {
    die 'Do not use bare MT::Plugins::Test::Request';
}

sub cgi_file {
    die 'Do not use bare MT::Plugins::Test::Request';
}

sub signin_default { 0 }

sub cgi_path {
    my $pkg = shift;
    my $config = MT->instance->config;
    $config->CGIPath;
}

sub uri {
    my $self = shift;

    my $uri = caturl( $self->cgi_path, $self->cgi_file );
    $uri .= $self->uri_params(@_);

    $uri;
}

sub signin_uri {
    my $self = shift;
    $self->uri;
}

sub cgi_dir_path {
    my $self = shift;

    my $config = MT->instance->config;
    my $path = $config->CGIDirPath || return;
    return unless -d $path;

    $path;
}

sub cgi_file_path {
    my $self = shift;

    my $path = $self->cgi_dir_path || return;
    $path = File::Spec->catdir($path, $self->cgi_file);
    return unless -f $path;

    $path;
}

sub uri_params {
    my $pkg = shift;
    my %params = @_;

    my $query = '';
    if ( %params ) {
        $query .= '?';
        $query .= join( '&', map {
            encode_url($_) . '=' . encode_url($params{$_})
        } keys %params );
    }

    $query;
}

sub build_mech {
    my $self = shift;
    my %args = @_;

    my $timeout = $args{timeout};
    $timeout = $DEFAULT_TIMEOUT unless defined $timeout;
    my $agent = $args{agent} || $DEFAULT_USER_AGENT;
    my $init = $args{init} || {};
    my $via = lc($args{via} || 'bootstrap');

    die 'Fill CGIPath or AdminCGIPath from protocol'
        if $via eq 'http' && $self->uri !~ m!^https?://!;

    die 'Set CGIDirPath or AdminCGIDirPath from protocol'
        if $via eq 'process' && !$self->cgi_file_path;

    $init->{agent} = $agent if $agent;
    $init->{timeout} = $timeout;
    $init->{cookie_jar} = {};

    my $package = 'WWW::Mechanize';
    $package .= '::CGI' if $via eq 'bootstrap' || $via eq 'process';

    my $mech = $package->new(%$init);

    if ( $via eq 'bootstrap' ) {
        $mech->cgi(sub {
            local $MT::mt_inst;
            $ENV{HTTP_USER_AGENT} = $agent if $agent;
            MT::Bootstrap->import( App => $self->app_class );
        });
        $mech->fork(1);
    }

    $mech->cgi_application($self->cgi_file_path)
        if $via eq 'process';

    $mech;
}

sub test_mech {
    my $self = shift;
    my %args = @_;
    my $test = $args{test};
    my $via = $args{via};

    if ( !defined($via) || ref $via eq 'ARRAY' ) {
        $via ||= \@VIA;
        foreach my $v ( @$via ) {
            subtest "via: $v" => sub {
                local $args{via} = $v;
                my $mech = $self->build_mech(%args);
                $test->($mech);
            };
        }
    } else {
        my $mech = $self->build_mech(%args);
        $test->($mech);
    }
}

sub test_user_mech {
    my $self = shift;
    my %args = @_;

    my $author = $args{user} || {};
    my $test = $args{test};
    my $roles = $args{as_roles};
    my $as_superuser = $args{as_superuser};
    my $signin = $args{signin};
    $signin = $self->signin_default unless defined $signin;

    return error('user requires as hash on test_cms_mech')
        unless ref $author eq 'HASH';

    return error('roles requires as hash on test_cms_mech')
        if $roles && ref $roles ne 'HASH';

    $author->{name} ||= $DEFAULT_NAME;
    my $password = delete $author->{password} || $DEFAULT_PASSWORD;

    test_object
        model => 'author',
        template => $args{template} || 'common_author',
        values => $author,
        post_save => sub {
            my $author = shift;

            # Fixed password
            $author->set_password($password);

            # As superuser?
            $author->is_superuser(1) if $as_superuser;

            $author->save;

            # Assign roles
            if ( $roles ) {
                for my $blog_id ( keys %$roles ) {
                    return error('empty blog_id') unless $blog_id;
                    my $blog = MT->model('website')->load($blog_id)
                        || MT->model('blog')->load($blog_id)
                        || return error('unknown blog_id: ' . $blog_id);
                    my $blog_roles = $roles->{$blog_id};
                    $blog_roles = [$blog_roles] unless ref $blog_roles;
                    return error('each roles requires scalar or array')
                        unless ref $blog_roles ne 'ARRAY';

                    for my $r ( @$blog_roles ) {
                        my $role = MT->model('role')->load({
                            name => MT->translate($r),
                        });
                        return error('unknown role: ' . $r) unless $role;
                        $author->add_role($role, $blog);
                    }
                }
            }
        },
        test => sub {
            my $author = shift;
            my $mech = $self->build_mech(%args);

            if ( $signin ) {
                my $res = $mech->post($self->signin_uri, { username => $author->name, password => $password });
            }

            my $via = $args{via};
            if ( !defined($via) || ref $via eq 'ARRAY' ) {
                $via ||= \@VIA;
                foreach my $v ( @$via ) {
                    subtest "via: $v" => sub {
                        local $args{via} = $v;
                        my $mech = $self->build_mech(%args);
                        $test->($mech, $author, $password);
                    };
                }
            } else {
                $test->($mech, $author, $password);
            }
        };
}

1;
