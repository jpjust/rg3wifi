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

=head2 access_denied

Handle Catalyst::Plugin::Authorization::ACL access denied exceptions

=cut

sub access_denied : Private {
	my ($self, $c) = @_;
	$c->stash->{error_msg} = 'Você não tem permissão para acessar este recurso.';
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

=head2 get_ip

Gera um número IP de acordo com o plano do cliente.

=cut

sub get_ip : Private {
	my ($c, $plano) = @_;
	
	# Verifica o plano
	my $base;
	if    ($plano == 1)	{ $base = 16; }
	elsif ($plano == 2)	{ $base = 32; }
	
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
	
	return $ip;
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
	$c->stash->{grupos} = [$c->model('RG3WifiDB::Grupos')->all];
	$c->stash->{acao} = 'novo';
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 editar

Exibe página para edição do cliente.

=cut

sub editar : Local {
	my ($self, $c, $uid) = @_;

	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;

	# Verifica permissões
	if (($cliente->grupo->nome eq 'admin') && (!$c->check_user_roles('admin'))) {
		$c->stash->{error_msg} = 'Você não tem permissão para editar um administrador!';
		$c->stash->{template} = 'erro.tt2';
		return;
	}

	$c->stash->{cliente} = $cliente; 
	$c->stash->{planos} = [$c->model('RG3WifiDB::Planos')->all];
	$c->stash->{grupos} = [$c->model('RG3WifiDB::Grupos')->all];
	$c->stash->{acao} = 'editar';
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 cadastro_do

Efetua o cadastro/atualizacao do cliente.

=cut

sub cadastro_do : Local {
	my ($self, $c) = @_;
	
	# Verifica as senhas
	if ($c->request->params->{pwd1} ne $c->request->params->{pwd2}) {
		$c->stash->{error_msg} = 'As senhas digitadas não coincidem.';
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Faz as devidas inserções no banco de dados
	my $cliente = undef;
	my $ip = get_ip($c, $c->request->params->{plano});
	my $dados = {
		id_plano		=> $c->request->params->{plano}				|| undef,
		login			=> $c->request->params->{login}				|| undef,
		senha			=> $c->request->params->{pwd1}				|| undef,
		bloqueado		=> $c->request->params->{bloqueado}			|| 0,
		nome			=> $c->request->params->{nome}				|| undef,
		rg				=> $c->request->params->{rg}				|| undef,
		doc				=> $c->request->params->{doc}				|| undef,
		data_nascimento	=> $c->request->params->{data_nascimento}	|| undef,
		endereco		=> $c->request->params->{endereco}			|| undef,
		bairro			=> $c->request->params->{bairro}			|| undef,
		cep				=> $c->request->params->{cep}				|| undef,
		telefone		=> $c->request->params->{telefone}			|| undef,
		observacao		=> $c->request->params->{observacao}		|| undef,
	};
	
	eval {
		# Cria novo usuário
		if ($c->request->params->{acao} eq 'novo') {
			$cliente = $c->model('RG3WifiDB::Usuarios')->create($dados);
			$cliente->update({ip => $ip});
			if ($c->check_any_user_role('admin')) {
				$cliente->update({id_grupo => $c->request->params->{grupo}});
			}
		}
		# Edita usuário já cadastrado
		elsif ($c->request->params->{acao} eq 'editar') {
			$cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $c->request->params->{uid}})->first;
			if (!$cliente) {
				$c->stash->{error_msg} = 'Cliente não encontrado!';
				$c->stash->{template} = 'erro.tt2';
				return;
			}

			# Verifica permissões
			if (($cliente->grupo->nome eq 'admin') && (!$c->check_user_roles('admin'))) {
				$c->stash->{error_msg} = 'Você não tem permissão para editar um administrador!';
				$c->stash->{template} = 'erro.tt2';
				return;
			}
			
			# Mudança de plano, obtém novo IP de acordo com o novo plano
			if ($cliente->id_plano != $c->request->params->{plano}) { $cliente->update({ip => $ip}); }
			
			$cliente->update($dados);
			if ($c->check_any_user_role('admin')) {
				$cliente->update({id_grupo => $c->request->params->{grupo}});
			}
		}
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Ocorreu um erro ao inserir os dados do cliente. Verifique se o formulário foi preenchido corretamente.';
		$c->log->debug($@);
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Atualiza as tabelas do PPPoE
	if ($c->request->params->{bloqueado}) {
		&user_del($c, $cliente->uid);
	} else {
		&user_add($c, $cliente->uid);
	}
	
	# Envia mensagem de sucesso
	$c->stash->{status_msg} = 'Cliente cadastrado/alterado com sucesso!';
	if ($c->request->params->{acao} eq 'novo') {
		$c->forward('novo');
	} else {
		$c->forward('lista');
	}
}

=head2 excluir

Exclui um usuário do sistema.

=cut

sub excluir : Local {
	my ($self, $c, $uid) = @_;
	
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	if (!$cliente) {
		$c->stash->{error_msg} = 'Cliente não encontrado!';
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Exclui o cliente
	&user_del($c, $cliente->login);
	$cliente->delete();
	
	# Exibe mensagem de sucesso
	$c->stash->{status_msg} = 'Cliente excluído com sucesso.';
	$c->forward('lista');
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
