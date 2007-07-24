package RG3Wifi::Controller::Cadastro;

use strict;
use warnings;
use base 'Catalyst::Controller';
use EasyCat;
use Data::FormValidator;

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
	$c->model('RG3WifiDB::radcheck')->create({
		UserName	=> $cliente->login,
		Attribute	=> 'Password',
		Value		=> $cliente->senha,
	});
	
	# Tabela usergroup
	$c->model('RG3WifiDB::usergroup')->create({
		UserName	=> $cliente->login,
		GroupName	=> 'cliente',
	});
	
	# Tabela radreply
	$c->model('RG3WifiDB::radreply')->create({
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
	
	$c->model('RG3WifiDB::radcheck')->search({UserName => $cliente->login})->delete_all();
	$c->model('RG3WifiDB::radreply')->search({UserName => $cliente->login})->delete_all();
	$c->model('RG3WifiDB::usergroup')->search({UserName => $cliente->login})->delete_all();
}

=head2 remake_users

Refaz a lista de usuários o PPPoE.

=cut

sub remake_users : Local {
	my ($self, $c) = @_;
	
	# Limpa os dados atuais
	$c->model('RG3WifiDB::radcheck')->delete_all();
	$c->model('RG3WifiDB::radreply')->delete_all();
	$c->model('RG3WifiDB::usergroup')->delete_all();
	
	# Recadastra os usuários
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->all) {
		if (!$cliente->bloqueado) {
			&user_add($c, $cliente->uid);
		}
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Lista de usuários PPPoE refeita!';
	$c->forward('lista');
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

=head2 lista_p

Exibe formulário para impressão de cadastros.

=cut

sub lista_p : Local {
	my ($self, $c) = @_;
	$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->all];
	$c->stash->{template} = 'cadastro/impressao.tt2';
}

=head2 imprimir

Exibe os cadastros prontos para impressão.

=cut

sub imprimir : Local {
	my ($self, $c) = @_;
	my $p = $c->request->params;
	
	if ($p->{selecao} == 1) {
		$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->search({uid => $p->{cliente_1}})];
	} elsif ($p->{selecao} == 2) {
		$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->search({uid => [$p->{cliente_2}]})];
	} else {
		$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->all];
	}
	
	$c->stash->{template} = 'cadastro/papel.tt2';
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

=head2 cadastro_do

Efetua o cadastro/atualizacao do cliente.

=cut

sub cadastro_do : Local {
	my ($self, $c) = @_;

	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = {
		uid				=> $p->{uid}									|| undef,
		id_plano		=> $p->{plano}									|| undef,
		login			=> $p->{login}									|| undef,
		senha			=> $p->{pwd1}									|| undef,
		bloqueado		=> $p->{bloqueado}								|| 0,
		nome			=> $p->{nome}									|| undef,
		rg				=> $p->{rg}										|| undef,
		doc				=> $p->{doc}									|| undef,
		data_nascimento	=> &EasyCat::data2sql($p->{data_nascimento})	|| undef,
		endereco		=> $p->{endereco}								|| undef,
		bairro			=> $p->{bairro}									|| undef,
		cep				=> $p->{cep}									|| undef,
		telefone		=> $p->{telefone}								|| undef,
		observacao		=> $p->{observacao}								|| undef,
	};
	
	# Verifica as senhas
	if ($p->{pwd1} ne $p->{pwd2}) {
		$c->stash->{error_msg} = 'As senhas digitadas não coincidem.';
		$c->stash->{cliente} = $dados;
		$c->forward('novo');
		return;
	}
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(id_plano login senha nome rg doc data_nascimento endereco bairro cep telefone)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{cliente} = $dados;
		$c->forward('novo');
		return;
	}

	# O usuário admin pode escolher o grupo
	if ($c->check_any_user_role('admin')) {
		$dados->{id_grupo} = $p->{grupo};
	}
	
	# Faz as devidas inserções no banco de dados
	my $cliente = undef;
	my $ip = get_ip($c, $p->{plano});
	
	eval {
		# Cria novo usuário
		if ($p->{acao} eq 'novo') {
			$cliente = $c->model('RG3WifiDB::Usuarios')->create($dados);
			$cliente->update({ip => $ip});
		}
		# Edita usuário já cadastrado
		elsif ($p->{acao} eq 'editar') {
			$cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $p->{uid}})->first;
			if (!$cliente) {
				$c->stash->{error_msg} = 'Cliente não encontrado!';
				$c->forward('lista');
				return;
			}

			# Verifica permissões
			if (($cliente->grupo->nome eq 'admin') && (!$c->check_user_roles('admin'))) {
				$c->stash->{error_msg} = 'Você não tem permissão para editar um administrador!';
				$c->forward('lista');
				return;
			}
			
			# Mudança de plano, obtém novo IP de acordo com o novo plano
			if ($cliente->id_plano != $p->{plano}) { $cliente->update({ip => $ip}); }
			
			$cliente->update($dados);
		}
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar cliente: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Atualiza as tabelas do PPPoE
	if ($p->{bloqueado}) {
		&user_del($c, $cliente->uid);
	} else {
		&user_add($c, $cliente->uid);
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Cliente cadastrado/editado com sucesso.';
	$c->forward('lista');
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
		$c->forward('lista');
		return;
	}

	$c->stash->{cliente} = $cliente; 
	$c->stash->{planos} = [$c->model('RG3WifiDB::Planos')->all];
	$c->stash->{grupos} = [$c->model('RG3WifiDB::Grupos')->all];
	$c->stash->{acao} = 'editar';
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 excluir

Exclui um usuário do sistema.

=cut

sub excluir : Local {
	my ($self, $c, $uid) = @_;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	&user_del($c, $uid);
	$cliente->delete();
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
