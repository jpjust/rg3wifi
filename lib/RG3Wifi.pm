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

our $VERSION = '0.04.2';

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
# Cadastro (geral)
__PACKAGE__->allow_access_if("/cadastro",					[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro",					[qw/operador/]);
__PACKAGE__->deny_access("/cadastro");

# Cadastro (exclusão)
__PACKAGE__->allow_access_if("/cadastro/excluir",			[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/excluir");

__PACKAGE__->allow_access_if("/cadastro/excluir_conta",		[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/excluir_conta");

# Cadastro (aviso)
__PACKAGE__->allow_access_if("/cadastro/aviso_do", 			[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/aviso_do");
__PACKAGE__->allow_access_if("/cadastro/aviso_undo", 		[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/aviso_undo");
__PACKAGE__->allow_access_if("/cadastro/aviso_cria_lista",	[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/aviso_cria_lista");

# Cadastro (bloqueio)
__PACKAGE__->allow_access_if("/cadastro/bloqueio_do", 		[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/bloqueio_do");
__PACKAGE__->allow_access_if("/cadastro/bloqueio_undo", 	[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/aviso_undo");
__PACKAGE__->allow_access_if("/cadastro/remake_users",		[qw/admin/]);
__PACKAGE__->deny_access("/cadastro/remake_users");

# Rádios (geral)
__PACKAGE__->allow_access_if("/radios",						[qw/admin/]);
__PACKAGE__->allow_access_if("/radios",						[qw/operador/]);
__PACKAGE__->deny_access("/radios");

# Rádios (exclusão)
__PACKAGE__->allow_access_if("/radios/excluir_fab",			[qw/admin/]);
__PACKAGE__->deny_access("/radios/excluir_fab");
__PACKAGE__->allow_access_if("/radios/excluir_mod",			[qw/admin/]);
__PACKAGE__->deny_access("/radios/excluir_mod");
__PACKAGE__->allow_access_if("/radios/excluir_rad",			[qw/admin/]);
__PACKAGE__->deny_access("/radios/excluir_rad");

# Chamados (geral)
__PACKAGE__->allow_access_if("/chamados",					[qw/admin/]);
__PACKAGE__->allow_access_if("/chamados",					[qw/operador/]);
__PACKAGE__->deny_access("/chamados");

# Chamados (exclusão)
__PACKAGE__->allow_access_if("/chamados/excluir",			[qw/admin/]);
__PACKAGE__->deny_access("/chamados/excluir");


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
