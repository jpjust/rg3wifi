package RG3Wifi;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst qw/
	-Debug
	ConfigLoader
	Static::Simple
	
	Authentication
	Authentication::Store::DBIC
	Authentication::Credential::Password
	Authorization::Roles
	Authorization::ACL
	
	Session
	Session::Store::FastMmap
	Session::State::Cookie
	/;

our $VERSION = '0.31';

# Configure the application. 
#
# Note that settings in RG3Wifi.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'RG3Wifi' );

# Start the application
__PACKAGE__->setup;

# Authorization::ACL Rules
# O controller Acesso é liberado pra todo mundo.

##### Auditoria (geral)
__PACKAGE__->allow_access_if("/auditoria",						[qw/admin/]);
__PACKAGE__->deny_access("/auditoria");

##### Cadastro (admin)
__PACKAGE__->allow_access_if("/cadastro",						[qw/admin/]);

# Cadastro (operador)
__PACKAGE__->allow_access_if("/cadastro/abrir_chamado",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/busca",					[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/cadastro_conta_do",		[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/cadastro_do",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/editar",				[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/editar_conta",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/filtro",				[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/imprimir",				[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/index",					[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/lista",					[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/lista_p",				[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/nova_conta",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/novo",					[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/limpa_pppoe",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/limpa_pppoe1",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/derrubar_pppoe_do",		[qw/operador/]);

# Cadastro (outros)
__PACKAGE__->deny_access("/cadastro");

##### Caixa (geral)
__PACKAGE__->allow_access_if("/caixa",							[qw/admin/]);
__PACKAGE__->deny_access("/caixa");

##### Chamados (admin, operador)
__PACKAGE__->allow_access_if("/chamados",						[qw/admin/]);
__PACKAGE__->allow_access_if("/chamados",						[qw/operador/]);

# Chamados (outros)
__PACKAGE__->deny_access("/chamados");

###### Rádios (admin, operador)
__PACKAGE__->allow_access_if("/radios",							[qw/admin/]);
__PACKAGE__->allow_access_if("/radios",							[qw/operador/]);

# Rádios (outros)
__PACKAGE__->deny_access("/radios");

=head1 NAME

RG3Wifi - Catalyst based application

=head1 SYNOPSIS

    script/rg3wifi_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<RG3Wifi::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
