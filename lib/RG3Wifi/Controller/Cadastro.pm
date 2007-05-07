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

=head2 user_add

Adiciona/atualiza um usuário na configuração do PPPoE.

=cut

sub user_add : Private {
	my ($c, $uid) = @_;
	
	if (@_ < 2) { return 1; }

	&user_del($c, $uid);

	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	if (!$cliente)	{ return 2; }
	
	# Tabela radcheck
	my $radcheck = $c->model('RG3WifiDB::radcheck')->create({
		UserName	=> $cliente->login,
		Attribute	=> 'Password',
		Value		=> $cliente->senha,
	});
	
	# Tabela usergroup
	my $usergroup = $c->model('RG3WifiDB::usergroup')->create({
		UserName	=> $cliente->login,
		GroupName	=> 'cliente',
	});
	
	# Tabela radreply
	my $radreply = $c->model('RG3WifiDB::radreply')->create({
		UserName	=> $cliente->login,
		Attribute	=> 'Framed-IP-Address',
		Value		=> $cliente->ip,
	});
}

=head2 user_del

Remove um usuário da configuração do PPPoE.

=cut

sub user_del : Private {
	my ($c, $uid) = @_;
	
	if (@_ < 2) { return 1; }
	
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	if (!$cliente)	{ return 2; }
	
	my $radcheck	= $c->model('RG3WifiDB::radcheck')->search({UserName => $cliente->login})->first;
	if ($radcheck)	{ $radcheck->delete; }
	my $radreply	= $c->model('RG3WifiDB::radreply')->search({UserName => $cliente->login})->first;
	if ($radreply)	{ $radreply->delete; }
	my $usergroup	= $c->model('RG3WifiDB::usergroup')->search({UserName => $cliente->login})->first;
	if ($usergroup)	{ $usergroup->delete; }
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
	$c->stash->{planos} = [$c->model('RG3WifiDB::Planos')->all];
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
	my $cliente = undef;
	eval {
		# Tabela de usuários
		$cliente = $c->model('RG3WifiDB::Usuarios')->create({
			id_grupo	=> 3,
			id_plano	=> $c->request->params->{plano}		|| undef,
			login		=> $c->request->params->{login}		|| undef,
			senha		=> $c->request->params->{pwd1}		|| undef,
			bloqueado	=> $c->request->params->{bloqueado}	|| 0,
			nome		=> $c->request->params->{nome}		|| undef,
			ip			=> $ip,
		});
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Ocorreu um erro ao cadastrar o cliente. Verifique se este login já existe.';
		$c->log->debug($@);
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Atualiza as tabelas do PPPoE
	&user_add($c, $cliente->uid);
	
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
	$c->stash->{planos} = [$c->model('RG3WifiDB::Planos')->all];
	$c->stash->{acao} = 'editar_do';
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 editar_do

Altera o cadastro do cliente.

=cut

sub editar_do : Local {
	my ($self, $c) = @_;
	
	# Busca pelo cliente a editar
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $c->request->params->{id}})->first;
	if (!$cliente) {
		$c->stash->{error_msg} = 'Cliente não encontrado!';
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Atualiza o cadastro do cliente
	$cliente->update({
		id_plano	=> $c->request->params->{plano}		|| undef,
		login		=> $c->request->params->{login}		|| undef,
		senha		=> $c->request->params->{pwd1}		|| undef,
		bloqueado	=> $c->request->params->{bloqueado}	|| 0,
		nome		=> $c->request->params->{nome}		|| undef,
	});
	
	# Atualiza as tabelas do PPPoE
	if ($c->request->params->{bloqueado}) {
		&user_del($c, $cliente->uid);
	} else {
		&user_add($c, $cliente->uid);
	}

	# Envia mensagem de sucesso
	$c->stash->{status_msg} = 'Cliente atualizado com sucesso!';
	$c->forward('lista');
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
