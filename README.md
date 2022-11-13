# NAME

Mojo::WebSocketProxy - WebSocket proxy for JSON-RPC 2.0 server

# SYNOPSIS

     # lib/your-application.pm

     use parent 'Mojolicious';

     sub startup {
         my $self = shift;
         $self->plugin(
             'web_socket_proxy' => {
                 actions => [
                     ['json_key', {some_param => 'some_value'}]
                 ],
                 base_path => '/api',
                 url => 'http://rpc-host.com:8080/',
             }
         );
    }

Or to manually call RPC server:

     # lib/your-application.pm

     use parent 'Mojolicious';

     sub startup {
         my $self = shift;
         $self->plugin(
             'web_socket_proxy' => {
                 actions => [
                     [
                         'json_key',
                         {
                             instead_of_forward => sub {
                                 shift->call_rpc({
                                     args   => [ qw(args here) ],
                                     method => 'json_key', # it'll call 'http://rpc-host.com:8080/json_key'
                                     rpc_response_cb => sub {...}
                                 });
                             }
                         }
                     ]
                 ],
                 base_path => '/api',
                 url => 'http://rpc-host.com:8080/',
             }
         );
    }

# DESCRIPTION

Using this module you can forward WebSocket-JSON requests to RPC server.

For every message it creates separate hash ref storage, which is available from hooks as $req\_storage.
Request storage have RPC call parameters in $req\_storage->{call\_params}.
It copies message args to $req\_storage->{call\_params}->{args}.
You can use Mojolicious stash to store data between messages in one connection.

# Proxy responses

The plugin sends websocket messages to client with RPC response data.
If RPC reponse looks like this:

    {status => 1}

It returns simple response like this:

    {$msg_type => 1, msg_type => $msg_type}

If RPC returns something like this:

    {
        response_data => [..],
        status        => 1,
    }

Plugin returns common response like this:

    {
        $msg_type => $rpc_response,
        msg_type  => $msg_type,
    }

You can customize ws proxy response using 'response' hook.

# Plugin parameters

The plugin understands the following parameters.

## actions

A reference to array of action details, which contain stash\_params,
request-response callbacks, other call parameters.

    $self->plugin(
        'web_socket_proxy' => {
            actions => [
                ['action1_json_key', {details_key1 => details_value1}],
                ['action2_json_key']
            ]
        });

## backends

An optional reference to a hash of alternate backends to pick for certain RPC
calls. Hash keys are names of backends, and values are themselves hash
references containing backend parameters. Currently only the `url` key is
supported.

    backends => {
        server2 => {url => "http://server2.rpc-host:8080/"},
    }

Alternate backends are selected by using the `backend` action option.

## rpc\_failure\_cb

A subroutine reference to call when the RPC call fails at the HTTP level.
Called with `Mojolicious::Controller` the rpc\_response
and `$req_storage`

A default rpc\_failure\_cb could be provided in the startup sub routine

     sub startup {
         my $self = shift;
         $self->plugin(
             'web_socket_proxy' => {
                 actions => [
                     ['json_key', {some_param => 'some_value'}]
                 ],
                 base_path => '/api',
                 url => 'http://rpc-host.com:8080/',
                 rpc_failure_cb => sub {
                     my ($c, $res, $req_storage, $error) = @_;
                     warn "RPC call failed";
                     return undef;
                 }

             }
         );
    }

Call specific sub routine could be specified in call\_rpc arguments

    $c->call_rpc({
        args           => $args,
        origin_args    => $req_storage->{origin_args},
        method         => 'ticks_history',
        rpc_failure_cb => sub {
            if ($worker) {
                warn "Something went wrong with this rpc call : " . $method;
                $worker->unregister;
            }
        },
    }

## before\_forward

    before_forward => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run after request is dispatched and before to start preparing RPC call.
It'll run every hook or until any hook returns some non-empty result.
If returns any hash ref then that value will be JSON encoded and send to client,
without forward action to RPC. To call RPC every hook should return empty or undefined value.
It's good place to some validation or subscribe actions.

## after\_forward

    after_forward => [sub { my ($c, $result, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run after every forwarded RPC call done.
Or even forward action isn't running.
It can view or modify result value from 'before\_forward' hook.
It'll run every hook or until any hook returns some non-empty result.
If returns any hash ref then that value will be JSON encoded and send to client.

## after\_dispatch

    after_dispatch => [sub { my $c = shift; ... }, sub {...}]

Global hooks which will run at the end of request handling.

## before\_get\_rpc\_response (global)

    before_get_rpc_response => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run when asynchronous RPC call is answered.

## after\_got\_rpc\_response (global)

    after_got_rpc_response => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run after checked that response exists.

## before\_send\_api\_response (global)

    before_send_api_response => [sub { my ($c, $req_storage, $api_response) = @_; ... }, sub {...}]

Global hooks which will run immediately before send API response.

## after\_sent\_api\_response (global)

    before_send_api_response => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run immediately after sent API response.

## base\_path

API url for make route.

## stream\_timeout

See ["timeout" in Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AStream#timeout)

## max\_connections

See ["max\_connections" in Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop#max_connections)

## max\_response\_size

Returns error if RPC response size is over value.

## opened\_connection

Callback for doing something once after connection is opened

## finish\_connection

Callback for doing something every time when connection is closed.

## url

RPC host url - store url string or function to set url dynamically for manually RPC calls.
When using forwarded call then url storing in request storage.
You can store url in every action options, or make it at before\_forward hook.

# Actions options

## stash\_params

    stash_params => [qw/ stash_key1 stash_key2 /]

Will send specified parameters from Mojolicious $c->stash.
You can store RPC response data to Mojolicious stash returning data like this:

    rpc_response => {
        stast => {..} # data to store in Mojolicious stash
        response_key1 => response_value1, # response to API client
        response_key2 => response_value2
    }

## success

    success => sub { my ($c, $rpc_response) = @_; ... }

Hook which will run if RPC returns success value.

## error

    error => sub { my ($c, $rpc_response) = @_; ... }

Hook which will run if RPC returns value with error key, e.g.

    { result => { error => { code => 'some_error' } } }

## response

    response => sub { my ($c, $rpc_response) = @_; ... }

Hook which will run every time when success or error callbacks is running.
It good place to modify API response format.

## backend

Selects an alternative backend to forward requests onto, rather than the
default.

    backend => "server2"

# SEE ALSO

[Mojolicious::Plugin::WebSocketProxy](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebSocketProxy),
[Mojo::WebSocketProxy](https://metacpan.org/pod/Mojo%3A%3AWebSocketProxy)
[Mojo::WebSocketProxy::Backend](https://metacpan.org/pod/Mojo%3A%3AWebSocketProxy%3A%3ABackend),
[Mojo::WebSocketProxy::Dispatcher](https://metacpan.org/pod/Mojo%3A%3AWebSocketProxy%3A%3ADispatcher),
[Mojo::WebSocketProxy::Config](https://metacpan.org/pod/Mojo%3A%3AWebSocketProxy%3A%3AConfig)
[Mojo::WebSocketProxy::Parser](https://metacpan.org/pod/Mojo%3A%3AWebSocketProxy%3A%3AParser)

# COPYRIGHT AND LICENSE

Copyright (C) 2016 binary.com
