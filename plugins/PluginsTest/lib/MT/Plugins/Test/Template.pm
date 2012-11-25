package MT::Plugins::Test::Template;

use strict;
use base 'Exporter';
use Carp;
use Try::Tiny;
use MT::Plugins::Test;

our @EXPORT = qw(test_template);

sub test_template {
    my %args = @_;
    my $template = $args{template} || Carp::confess('Requires template for test_template');
    my $stash = $args{stash} || {};
    my $vars = $args{vars} || {};
    my $test = $args{test} || Carp::confess('Requires test for test_template');

    require MT::Builder;
    require MT::Template::Context;
    my $builder = MT::Builder->new;
    my $ctx = MT::Template::Context->new;

    for my $key ( keys %$stash ) {
        $ctx->stash($key, $stash->{$key});
    }
    for my $key ( keys %$vars ) {
        $ctx->var($key, $vars->{$key});
    }

    my $text = $template;
    if ( ref $template ) {
        try {
            $text = $template->text;
        } catch {
            Carp::confess('Template has no text');
        };
    }

    my %args = (
        ctx => $ctx,
        builder => $builder,
        text => $text,
    );

    if ( my $tokens = $builder->compile($ctx, $text) ) {
        $args{tokens} = $tokens;

        if ( defined( my $result = $builder->build($ctx, $tokens) ) ) {
            $args{result} = $result;
        } else {
            $args{error} = $builder->errstr;
        }
    } else {
        $args{error} = $builder->errstr;
    }

    $test->(%args);
}

1;
__END__