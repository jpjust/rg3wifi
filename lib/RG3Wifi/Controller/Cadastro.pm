package RG3Wifi::Controller::Cadastro;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

RG3Wifi::Controller::Cadastro - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
	my ($self, $c) = @_;
	$c->forward('lista');
}

=head2 lista

Lista os clientes cadastrados.

=cut

sub lista : Local {
	my ($self, $c) = @_;
	
	$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->all];
	$c->stash->{template} = 'cadastro/lista.tt2';
}

=head2 novo

Abre página de cadastro de cliente.

=cut

sub novo : Local {
	my ($self, $c) = @_;
	$c->stash->{acao} = 'novo_do';
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 novo_do

Efetua o cadastro do cliente.

=cut

sub novo_do : Local {
	my ($self, $c) = @_;
	
	# Verifica as senhas
	if ($c->request->params->{pwd1} ne $c->request->params->{pwd2}) {
		$c->stash->{error_msg} = 'As senhas digitadas não coincidem.';
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Verifica o plano
	my $base;
	if ($c->request->params->{plano} == 1)		{ $base = 16; }
	elsif ($c->request->params->{plano} == 2)	{ $base = 32; }

	# Sorteia um IP e verifica se já existe
	my ($addr, $ip);
	while(1) {
		$addr = int(rand(4096));
		$ip = '172.16.' . (int($addr / 256) + $base) . '.' . ($addr % 256);

		my $verifica = $c->model('RG3WifiDB::radreply')->search({Value => $ip})->first;
		if ($verifica) {
			next;   # Já existe esse IP
		} else {
			last;
		}
	};

	# Faz as devidas inserções no banco de dados
	eval {
		# Tabela de usuários
		my $cliente = $c->model('RG3WifiDB::Usuarios')->create({
			id_grupo	=> 3,
			login		=> $c->request->params->{login}	|| undef,
			senha		=> $c->request->params->{pwd1}	|| undef,
			nome		=> $c->request->params->{nome}	|| undef,
		});
		
		# Tabela radcheck
		my $radcheck = $c->model('RG3WifiDB::radcheck')->create({
			UserName	=> $c->request->params->{login}	|| undef,
			Attribute	=> 'Password',
			Value		=> $c->request->params->{pwd1}	|| undef,
		});

		# Tabela usergroup
		my $usergroup = $c->model('RG3WifiDB::usergroup')->create({
			UserName	=> $c->request->params->{login}	|| undef,
			GroupName	=> 'cliente',
		});
		
		# Tabela radreply
		my $radreply = $c->model('RG3WifiDB::radreply')->create({
			UserName	=> $c->request->params->{login}	|| undef,
			Attribute	=> 'Framed-IP-Address',
			Value		=> "$ip"						|| undef,
		});

		# Atualiza as relações
		$cliente->update({
			id_radcheck		=> $radcheck->id,
			id_radreply		=> $radreply->id,
		});
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Ocorreu um erro ao cadastrar o cliente. Verifique se este login já existe.';
		$c->log->debug($@);
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Envia mensagem de sucesso
	$c->stash->{status_msg} = 'Cliente cadastrado com sucesso! Endereço IP do cliente: ' . $ip;
	$c->forward('novo');
}

=head2 editar

Exibe página para edição do cliente.

=cut

sub editar : Local {
	my ($self, $c, $uid) = @_;
	$c->stash->{cliente} = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	$c->stash->{acao} = 'editar_do';
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 editar_do

Altera o cadastro do cliente.

=cut

sub editar_do : Local {
	
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
