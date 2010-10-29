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
	my ($self, $c) = @_;
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
	
	# Verifica se existe a conta
	my $pppoe = $c->model('RG3WifiDB::Contas')->search({uid => $conta})->first;
	if (!$pppoe) {
		$c->stash->{error_msg} = 'Conta não encontrada!';
		$c->forward('index');
		return;
	}
	
	# Verifica se essa conta pertence a esse usuário (apenas para usuários do grupo "cliente")
	if ((!$c->check_any_user_role(qw/admin operador/)) && ($pppoe->id_cliente != $c->user->cliente->uid)) {
		$c->stash->{error_msg} = 'Sem permissão!';
		$c->forward('index');
		return;
	}
	
	# Exibe o log
	my $conexoes = $c->model('RG3WifiDB::radacct')->search({UserName => $pppoe->login})->page($pagina);
	$c->stash->{conexoes} = [$conexoes->all];
	$c->stash->{paginas} = $conexoes->pager->last_page;
	$c->stash->{pagina} = $pagina;
	$c->stash->{conta} = $conta;
	$c->stash->{login} = $pppoe->login;
	$c->stash->{cliente} = $pppoe->cliente->nome;
	$c->stash->{pppoe} = $pppoe;
	$c->stash->{template} = 'acesso/logs.tt2';
}

=head2 senha

Exibe página para alteração de senha.

=cut

sub senha : Local {
	my ($self, $c, $uid) = @_;
	my $conta = $c->model('RG3WifiDB::Contas')->search({uid => $uid})->first;
	if (!$conta) {
		$c->stash->{error_msg} = 'Conta não encontrada!';
		$c->forward('index');
		return;
	}

	# Verifica se essa conta pertence a esse usuário
	if ($conta->id_cliente != $c->user->cliente->uid) {
		$c->stash->{error_msg} = 'Sem permissão!';
		$c->forward('index');
		return;
	}
	
	$c->stash->{conta} = $conta;
	$c->stash->{template} = 'acesso/senha.tt2';
}

=head2 senha_do

Altera a senha do usuário.

=cut

sub senha_do : Local {
	my ($self, $c) = @_;

	# Parâmetros
	my $p = $c->request->params;
	my $pppoe = $c->model('RG3WifiDB::Contas')->search({uid => $p->{uid}})->first;
	my $cliente = $pppoe->cliente;

	# Verifica se essa conta pertence a esse usuário
	if ($pppoe->id_cliente != $c->user->cliente->uid) {
		$c->stash->{error_msg} = 'Sem permissão!';
		$c->forward('index');
		return;
	}
	
	# Efetua o cadastro
	my $dados = {
		uid				=> $p->{uid}					|| -1,
		login			=> $p->{login}					|| undef,
		senha			=> $p->{pwd1}					|| undef,
	};
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(uid login senha)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{conta} = $dados;
		$c->stash->{template} = 'acesso/senha.tt2';
		return;
	}
	
	# Verifica as senhas
	if ($p->{pwd1} ne $p->{pwd2}) {
		$c->stash->{error_msg} = 'As senhas digitadas não coincidem.';
		$dados->{senha} = '';
		$c->stash->{conta} = $dados;
		$c->stash->{template} = 'acesso/senha.tt2';
		return;
	}

	# Faz as devidas inserções no banco de dados
	eval {
		$c->model('RG3WifiDB::Contas')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao alterar senha: ' . $@;
		$c->stash->{template} = 'error.tt2';
		return;
	}
	
	# Atualiza as tabelas do PPPoE
	if ($cliente->bloqueado == 0) {
		&RG3Wifi::Controller::Cadastro::user_add($c, $p->{uid});
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Senha alterada com sucesso.';
	$c->forward('index');
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
