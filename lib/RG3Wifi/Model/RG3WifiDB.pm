package RG3Wifi::Model::RG3WifiDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'RG3WifiDB',
    connect_info => [
        'dbi:mysql:database=radius;host=peixoto',
        'radius',
        'radpwd',
        { AutoCommit => 1 },
        
    ],
);

=head1 NAME

RG3Wifi::Model::RG3WifiDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<RG3Wifi>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<RG3WifiDB>

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
