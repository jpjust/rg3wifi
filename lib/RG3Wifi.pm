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

our $VERSION = '0.34';

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

# Cadastro (segunda via de boleto para usuarios)
__PACKAGE__->allow_access("/cadastro/seleciona_banco");
__PACKAGE__->allow_access("/cadastro/imprime_boleto");
__PACKAGE__->allow_access("/cadastro/codigo_barras_img");
__PACKAGE__->allow_access("/cadastro/detalhar_fatura");

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
__PACKAGE__->allow_access_if("/cadastro/imprime_carne",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/index",					[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/lista",					[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/lista_p",				[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/nova_conta",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/novo",					[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/limpa_pppoe",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/limpa_pppoe1",			[qw/operador/]);
__PACKAGE__->allow_access_if("/cadastro/derrubar_pppoe_do",		[qw/operador/]);

# Cadastro (caixa)
__PACKAGE__->allow_access_if("/cadastro/abrir_chamado",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/busca",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/cadastro_conta_do",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/cadastro_do",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/editar",				[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/editar_conta",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/filtro",				[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/imprimir",				[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/imprime_carne",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/index",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/lista",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/lista_p",				[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/nova_conta",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/novo",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/limpa_pppoe",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/limpa_pppoe1",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/derrubar_pppoe_do",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/nova_fatura",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/nova_fatura_do",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/seleciona_banco",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/imprime_boleto",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/liquidar_fatura",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/liquidar_fatura_do",	[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/bloqueio_do",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/bloqueio_undo",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/bloqueio_pppoe_do",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/bloqueio_pppoe_undo",	[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/stats",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/lista_inadimplentes",	[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/lista_faturas_abertas",	[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/relatorio_faturas_do",	[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/chart_instalacoes",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/chart_mensalidade",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/cadastro/chart_planos",			[qw/caixa/]);

# Cadastro (outros)
__PACKAGE__->deny_access("/cadastro");

##### Caixa (admin)
__PACKAGE__->allow_access_if("/caixa",							[qw/admin/]);

# Caixa (caixa)
__PACKAGE__->allow_access_if("/caixa/index",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/atualiza_saldo",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/chart_movimentacao",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/filtro",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/gera_lista",				[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/lista",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/lista_loja",				[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/novo",						[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/novo_do",					[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/saldo_anterior_do",		[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/saldo_atual_do",			[qw/caixa/]);
__PACKAGE__->allow_access_if("/caixa/chart_movimentacao",		[qw/caixa/]);

# Caixa (outros)
__PACKAGE__->deny_access("/caixa");

##### Chamados (admin, operador, caixa)
__PACKAGE__->allow_access_if("/chamados",						[qw/admin/]);
__PACKAGE__->allow_access_if("/chamados",						[qw/operador/]);
__PACKAGE__->allow_access_if("/chamados",						[qw/caixa/]);

# Chamados (outros)
__PACKAGE__->deny_access("/chamados");

###### Rádios (admin, operador, caixa)
__PACKAGE__->allow_access_if("/radios",							[qw/admin/]);
__PACKAGE__->allow_access_if("/radios",							[qw/operador/]);
__PACKAGE__->allow_access_if("/radios",							[qw/caixa/]);

# Rádios (outros)
__PACKAGE__->deny_access("/radios");

##### Vendas (geral)
#__PACKAGE__->allow_access_if("/vendas",							[qw/admin/]);
#__PACKAGE__->deny_access("/vendas");


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
