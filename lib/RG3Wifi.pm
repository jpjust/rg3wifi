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

our $VERSION = '0.20';

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

# Auditoria (geral)
__PACKAGE__->allow_access_if("/auditoria",						[qw/admin/]);
__PACKAGE__->deny_access("/auditoria");



# Caixa (geral)
__PACKAGE__->allow_access_if("/caixa",							[qw/admin/]);
__PACKAGE__->deny_access("/caixa");



# Cadastro (início)
__PACKAGE__->allow_access_if("/cadastro",						[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro",						[qw/operador/]);

# Cadastro (exclusão)
__PACKAGE__->allow_access_if("/cadastro/excluir",				[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/excluir_conta",			[qw/admin/]);

# Cadastro (bloqueio)
__PACKAGE__->allow_access_if("/cadastro/bloqueio_do", 			[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/bloqueio_undo", 		[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/bloqueio_automatico",	[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/remake_users",			[qw/admin/]);

# Cadastro (estatísticas)
__PACKAGE__->allow_access_if("/cadastro/stats",					[qw/admin/]);

# Cadastro (faturas)
__PACKAGE__->allow_access_if("/cadastro/gerar_faturas",			[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/gerar_faturas_do",		[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/nova_fatura",			[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/editar_fatura",			[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/nova_fatura_do",		[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/liquidar_fatura",		[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/liquidar_fatura_do",	[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/excluir_fatura",		[qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro/editar_fatura",			[qw/admin/]);

# Cadastro (fim)
__PACKAGE__->deny_access("/cadastro");



# Rádios (início)
__PACKAGE__->allow_access_if("/radios",							[qw/admin/]);
__PACKAGE__->allow_access_if("/radios",							[qw/operador/]);

# Rádios (exclusão)
__PACKAGE__->allow_access_if("/radios/excluir_fab",				[qw/admin/]);
__PACKAGE__->allow_access_if("/radios/excluir_mod",				[qw/admin/]);
__PACKAGE__->allow_access_if("/radios/excluir_rad",				[qw/admin/]);

# Rádios (fim)
__PACKAGE__->deny_access("/radios");



# Chamados (início)
__PACKAGE__->allow_access_if("/chamados",						[qw/admin/]);
__PACKAGE__->allow_access_if("/chamados",						[qw/operador/]);

# Chamados (exclusão)
__PACKAGE__->allow_access_if("/chamados/excluir",				[qw/admin/]);

# Chamados (fim)
__PACKAGE__->deny_access("/chamados");


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
