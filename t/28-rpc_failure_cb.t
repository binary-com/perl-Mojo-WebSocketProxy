use strict;
use warnings;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::MaybeUTF8 ':v1';
use Mojo::IOLoop;
use Future;
use Test::MockModule;

my $mocked_response = Test::MockModule->new('Mojo::Message::Response');
#simluate a WrongResponse error
$mocked_response->mock('is_success',      sub { return undef });
$mocked_response->mock('is_client_error', sub { return undef });

my $mocked_dispatcher = Test::MockModule->new('Mojo::WebSocketProxy::Dispatcher');
my $call_send_count = 0;
$mocked_dispatcher->mock('send', sub {$call_send_count++; return $mocked_dispatcher->original("send")->(@_)});
package t::FrontEnd {
    use base 'Mojolicious';
    our ($rpc_response_cb_called, $rpc_failure_cb_called, $failure_block_response);
    $t::FrontEnd::failure_block_response = 1;
    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [[
                        'success',
                        {
                            rpc_response_cb => sub {
                                $rpc_response_cb_called = 1;
                                return {"rpc_response_cb" => 'ok'};
                            },
                            rpc_failure_cb => sub {
                                my ($c, $res, $req_storage) = @_;
                                $c->send({json => {'rpc_failure_cb' => 'ok'}}, $req_storage) if $failure_block_response;
                                $rpc_failure_cb_called = 1;
                            },
                            failure_block_response => $failure_block_response,
                        }
                    ],
                ],
                base_path => '/api',
                url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
            });
    }
};

use Mojo::IOLoop;

$t::FrontEnd::failure_block_response = 1;
test_wsp {
    my ($t) = @_;
    $call_send_count = 0;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    ok(!$t::FrontEnd::rpc_response_cb_called, 'rpc response_cb is not called');
    ok($t::FrontEnd::rpc_failure_cb_called,   'rpc failure cb is called');
    is(decode_json_utf8($t->message->[1])->{rpc_failure_cb}, 'ok', 'send is called by rpc failure cb');
    is($call_send_count, 1, 'send called only once, in rpc_failure_cb');
}
't::FrontEnd';

$t::FrontEnd::failure_block_response = 0;
test_wsp {
    my ($t) = @_;
    $call_send_count = 0;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    ok(!$t::FrontEnd::rpc_response_cb_called, 'rpc response_cb is not called');
    ok($t::FrontEnd::rpc_failure_cb_called,   'rpc failure cb is called');
    is(decode_json_utf8($t->message->[1])->{error}{code}, 'WrongResponse', 'send is called after rpc_failure cb');
    is($call_send_count, 1, 'send called only once, after called rpc_failure_cb');
}
't::FrontEnd';

done_testing;
