use strict;
use warnings;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::MaybeUTF8 ':v1';
use Mojo::IOLoop;
use Future;

package t::FrontEnd {
    use base 'Mojolicious';
    # does not matter
    sub startup {
         my $self = shift;
         $self->plugin(
             'web_socket_proxy' => {
                actions => [
                    ['success'],
                ],
                base_path => '/api',
                url => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
             }
         );
    }
};

test_wsp {
    my ($t) = @_;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => 'invalid'})->finished_ok(1007);
} 't::FrontEnd';

done_testing;
