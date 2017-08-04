requires 'Class::Method::Modifiers';
requires 'Data::UUID';
requires 'Future';
requires 'Guard';
requires 'JSON';
requires 'JSON::XS';
requires 'MojoX::JSON::RPC', '0.10';
requires 'Mojolicious', '5.77';
requires 'Scalar::Util';
requires 'Variable::Disposition';
requires 'perl', '5.014';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on build => sub {
    requires 'Test::Mojo';
    requires 'Test::Simple', '0.44';
    requires 'Test::MockModule';
    requires 'Test::MockObject';
    requires 'Test::More';
    requires 'Test::TCP';
};
