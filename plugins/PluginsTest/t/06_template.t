use strict;
use warnings;

use Test::More tests => 1;
use FindBin qw($Bin);
use lib $Bin;
use MTPath;

use MT;
my $mt = MT->new(Config => test_config) or die MT->errstr;

use MT::Plugins::Test;
use MT::Plugins::Test::Object;
use MT::Plugins::Test::Template;

test_common_website(
    test => sub {
        my ( $website, $blog, $author, $password ) = @_;

        $blog->name('Blog Name');
        $blog->save;

        my %args = (
            stash => {
                blog => $blog,
                blog_id => $blog->id,
            },
            vars => {
                v => 'Variable',
            },
        );

        subtest 'Raw text template' => sub {
            plan tests => 5;

            test_template(
                %args,
                template => '<mt:BlogName> and <mt:Var name="v">',
                test => sub {
                    my %args = @_;
                    ok $args{ctx};
                    ok $args{builder};
                    ok $args{tokens};
                    is $args{text}, '<mt:BlogName> and <mt:Var name="v">';
                    is $args{result}, 'Blog Name and Variable';
                },
            );
        };

        subtest 'Object template' => sub {
            plan tests => 3;

            my $tmpl = test_plugin->load_tmpl('test.tmpl');
            isa_ok $tmpl, 'MT::Template';

            test_template(
                %args,
                template => $tmpl,
                test => sub {
                    my %args = @_;
                    is $args{text}, '<mt:BlogName> and <mt:Var name="v">';
                    is $args{result}, 'Blog Name and Variable';
                },
            );
        };
    },
);
