requires 'Class::Method::Modifiers';
requires 'Data::UUID';
requires 'Future';
requires 'Guard';
requires 'JSON::MaybeXS';
requires 'JSON::MaybeUTF8';
requires 'MojoX::JSON::RPC';
requires 'Mojolicious', '== 7.29';
requires 'Scalar::Util';
requires 'Variable::Disposition';
requires 'perl', '5.014';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '7.1101';
};

on build => sub {
    requires 'Test::Mojo';
    requires 'Test::Simple', '0.44';
    requires 'Test::MockModule';
    requires 'Test::MockObject';
    requires 'Test::More';
    requires 'Test::TCP';
};
