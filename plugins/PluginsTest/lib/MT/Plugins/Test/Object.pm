package MT::Plugins::Test::Object;

use utf8;
use strict;
use warnings;

use JSON;
use Try::Tiny;
use FindBin qw($Bin);
use File::Spec;
use base qw(MT::Plugins::Test Exporter);

use MT::Plugins::Test::Path;

our @TEMPLATE_DIRS;
our $TEMPLATE_EXT = '.json';
our @EXPORT = qw(test_object test_objects test_common_website);
our @EXPORT_OK = qw(common_website);

our $DEFAULT_PASSWORD = 'password';

{
    my @here = File::Spec->splitdir(__FILE__);
    pop @here;
    push @here, 'templates';

    push @TEMPLATE_DIRS, File::Spec->catdir($Bin, 'templates');
    push @TEMPLATE_DIRS, File::Spec->catdir(@here);
}

sub error {
    __PACKAGE__->SUPER::error(@_);
}

sub object_template {
    my $tmpl = shift;
    my $template = {};

    $tmpl .= $TEMPLATE_EXT;
    my $path;
    for my $template_dir ( @TEMPLATE_DIRS ) {
        $path = File::Spec->catdir($template_dir, $tmpl);
        if ( -f $path ) {
            open(my $fh, $path) or return error("Failure to open $path");
            binmode $fh;
            my $json = join('', <$fh>);
            close $fh;
            try {
                $template = from_json($json);
            } catch {
                return error("Failure to load $path as JSON: $_");
            };
            return $template;
        }
    }

    return error("Template: $tmpl is not exists in: " . join(',', @TEMPLATE_DIRS))
        unless -f $path;


}

sub test_objects {
    my %args = @_;
    my $values = $args{values};
    my $all_model = $args{model};
    my $test = $args{test};
    return error('test requires as code ref on test_objects')
        if ref $test ne 'CODE';
    my $arg = $args{arg};
    $values = $args{values} || {};

    my $all_pre_save = $args{pre_save};
    my $all_post_save = $args{post_save};
    my $remove_by_key = $args{remove_by_key};
    my $retain = $args{retain};

    my %objects;

    my $all_tmpl = $args{template};

    try {
        for my $key ( keys %$values ) {
            my %cols = %{$values->{$key}};

            my $model = delete $cols{_model} || $all_model;
            my $class = MT->model($model)
                or return error("Unknown model: $model");
            my $template = {};
            if ( my $tmpl = delete $cols{_template} ) {
                $template = object_template($tmpl);
            } elsif( $all_tmpl ) {
                $template = object_template($all_tmpl);
            }

            for my $tkey ( keys %$template ) {
                $cols{$tkey} = $template->{$tkey} unless defined $cols{$tkey};
            }
            delete $cols{$_} foreach qw/id created_on modified_on/;
            my $pre_save = delete $cols{_pre_save};
            my $post_save = delete $cols{_post_save};

            if ( $remove_by_key ) {
                my %terms = map { $_ => $cols{$_} } @$remove_by_key;
                $class->remove(\%terms);
            }

            my $obj = $class->new;
            $obj->set_values(\%cols);
            if ( $all_pre_save && ref $all_pre_save eq 'CODE' ) {
                $all_pre_save->($obj);
            }
            if ( $pre_save && ref $pre_save eq 'CODE' ) {
                $pre_save->($obj);
            }
            $obj->save or die $obj->errstr;
            if ( $all_post_save && ref $all_post_save eq 'CODE' ) {
                $all_post_save->($obj);
            }
            if ( $post_save && ref $post_save eq 'CODE' ) {
                $post_save->($obj);
            }

            $objects{$key} = $obj;
        }
    } catch {
        error($_);
        $_->remove foreach values %objects;
        %objects = ();
    };

    if ( %objects ) {
        try {
            $test->(\%objects, $arg);
        } catch {
            error($_);
        };
    }

    unless ( $retain ) {
        $_->remove foreach values %objects;
    }
}

sub test_object {
    my %args = @_;
    my $values = $args{values} || {};
    my $test = $args{test};
    return error('test requires as code ref on test_object')
        if ref $test ne 'CODE';

    $args{values} = {
        object => $values,
    };
    $args{test} = sub {
        my $objects = shift;
        $test->($objects->{object}, @_);
    };

    test_objects %args;
}

sub test_common_website {
    my %args = @_;

    my $author_args = $args{author} || {};
    my $author_values = $author_args->{values} || {};
    my $website_args = $args{website} || {};
    my $website_values = $website_args->{values} || {};
    my $blog_args = $args{blog} || {};
    my $blog_values = $blog_args->{values} || {};
    my $test = $args{test};
    my $no_theme = $args{no_theme};

    my $password = delete $author_values->{password} || $DEFAULT_PASSWORD;

    $website_values->{site_path} ||= dummy_site_path('website');
    $website_values->{site_url} ||= dummy_site_url('website');

    test_object
        model => 'author',
        template => $author_args->{template} || 'common_author',
        values => $author_values,
        test => sub {
            my $author = shift;

            test_object
                model => 'website',
                template => $args{website_template} || 'common_website',
                values => $website_values,
                test => sub {
                    my $website = shift;
                    $website->apply_theme unless $no_theme;

                    $blog_values->{parent_id} = $website->id;
                    test_object
                        model => 'blog',
                        template => $args{blog_template} || 'common_blog',
                        values => $blog_values,
                        test => sub {
                            my $blog = shift;
                            $blog->apply_theme unless $no_theme;

                            $test->($website, $blog, $author, $password);
                        };
                };
        };

}

1;
