package RG3Wifi::Controller::Acesso;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

RG3Wifi::Controller::Acesso - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
	my ( $self, $c ) = @_;
	$c->forward('inicio');
}

=head2 inicio

Exibe a página inicial do usuário.

=cut

sub inicio : Local {
	my ($self, $c) = @_;
	$c->stash->{cliente} = $c->user->cliente;
	$c->stash->{template} = 'acesso/inicio.tt2';
}

=head2 logs

Mostra log PPPoE da conta.

=cut

sub logs : Local {
	use integer;
	my ($self, $c, $conta, $pagina) = @_;
	
	$pagina = 1 unless($pagina);
	
	my $pppoe = $c->model('RG3WifiDB::Contas')->search({uid => $conta})->first;
	if (!$pppoe) {
		$c->stash->{error_msg} = 'Conta não encontrada!';
	}
	
	my $conexoes = $c->model('RG3WifiDB::radacct')->search({UserName => $pppoe->login})->page($pagina);
	$c->stash->{conexoes} = [$conexoes->all];
	$c->stash->{paginas} = $conexoes->pager->last_page;
	$c->stash->{pagina} = $pagina;
	$c->stash->{conta} = $conta;
	$c->stash->{login} = $pppoe->login;
	$c->stash->{cliente} = $pppoe->cliente->nome;
	$c->stash->{template} = 'acesso/logs.tt2';
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
