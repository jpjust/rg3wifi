package RG3Wifi::Controller::Cadastro;

use strict;
use warnings;
use base 'Catalyst::Controller';
use FindBin;
use lib "$FindBin::Bin/../..";
use EasyCat;
use Data::FormValidator;
use Business::BR::Ids;
use Text::Unaccent;

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
	$c->forward('RG3Wifi::Controller::Acesso', 'inicio');
}

=head2 radius_user_update

Atualiza cliente PPPoE no RADIUS (adiciona ou remove de acordo com situação e outros estados).

=cut

sub radius_user_update : Private {
	my ($c, $cliente) = @_;
	
	if ($cliente->id_situacao == 1) {
		foreach my $conta ($cliente->contas) {
			&user_add($c, $conta->uid);
		}
	} else {
		foreach my $conta ($cliente->contas) {
			&user_del($c, $conta->uid);
		}
	}
}

=head2 user_add

Adiciona/atualiza um usuário na configuração do PPPoE.

=cut

sub user_add : Private {
	my ($c, $uid) = @_;
	
	if (@_ < 2) { return 1; }

	&user_del($c, $uid);

	my $conta = $c->model('RG3WifiDB::Contas')->search({uid => $uid})->first;
	if (!$conta)	{ return 2; }
	
	# Pool de IP. Se está sob aviso, o pool é diferente
	my $pool;
	if ($conta->cliente->aviso) {
		$pool = $conta->plano->pool_name . 'a';
	} else {
		$pool = $conta->plano->pool_name;
	}
	
	# Tabela radcheck
	$c->model('RG3WifiDB::radcheck')->create({
		UserName	=> $conta->login,
		Attribute	=> 'Password',
		Value		=> $conta->senha,
	});
	$c->model('RG3WifiDB::radcheck')->create({
		UserName	=> $conta->login,
		Attribute	=> 'Pool-Name',
		op			=> ':=',
		Value		=> $pool,
	});
	
	# Tabela radusergroup
	$c->model('RG3WifiDB::radusergroup')->create({
		username	=> $conta->login,
		groupname	=> 'cliente',
	});
}

=head2 user_del

Remove um usuário da configuração do PPPoE.

=cut

sub user_del : Private {
	my ($c, $uid) = @_;
	
	if (@_ < 2) { return 1; }
	
	my $conta = $c->model('RG3WifiDB::Contas')->search({uid => $uid})->first;
	if (!$conta)	{ return 2; }
	
	$c->model('RG3WifiDB::radcheck')->search({UserName => $conta->login})->delete_all();
	#$c->model('RG3WifiDB::radreply')->search({UserName => $conta->login})->delete_all();
	$c->model('RG3WifiDB::radusergroup')->search({UserName => $conta->login})->delete_all();
}

=head2 remake_users

Refaz a lista de usuários o PPPoE.

=cut

sub remake_users : Local {
	my ($self, $c) = @_;
	
	# Limpa os dados atuais
	$c->model('RG3WifiDB::radcheck')->delete_all();
	$c->model('RG3WifiDB::radusergroup')->delete_all();
	
	# Popula as tabelas
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->all) {
		&radius_user_update($c, $cliente);		
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Lista de usuários PPPoE refeita!';
	$c->forward('lista');
}

=head2 lista

Lista os clientes cadastrados.

=cut

sub lista : Local {
	my ($self, $c, $situacao) = @_;
	$situacao = 1 unless $situacao;
	$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->search({id_situacao => $situacao})];
	$c->stash->{template} = 'cadastro/lista.tt2';
}

=head2 lista_doc

Lista os clientes com documentos inválidos.

=cut

sub lista_doc : Local {
	my ($self, $c) = @_;
	
	my @clientes = undef;
	
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->all) {
		next if (test_id('cpf', $cliente->doc) || test_id('cnpj', $cliente->doc));
		push(@clientes, $cliente);
	}
	
	$c->stash->{clientes} = [@clientes];
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

=head2 filtro

Lista os clientes de acordo com o filtro configurado.

=cut

sub filtro : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Filtro por data de instalação
	if ($p->{tipo} eq '0') {
		$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->search({data_adesao => {
			-between => [&EasyCat::data2sql($p->{data_inst1}), &EasyCat::data2sql($p->{data_inst2})]
		}})];
	}
	
	$c->stash->{template} = 'cadastro/lista.tt2';
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
	my $cliente = {id_grupo => 3};
	$c->stash->{grupos} = [$c->model('RG3WifiDB::Grupos')->all];
	$c->stash->{situacoes} = [$c->model('RG3WifiDB::UsuariosSituacao')->all];
	$c->stash->{acao} = 'novo';
	$c->stash->{cliente} = $cliente unless ($c->stash->{cliente});
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 nova_conta

Abre página de cadastro de conta PPPoE.

=cut

sub nova_conta : Local {
	my ($self, $c, $uid) = @_;
	$c->stash->{planos} = [$c->model('RG3WifiDB::Planos')->all];
	$c->stash->{cliente} = $uid;
	$c->stash->{acao} = 'novo';
	$c->stash->{template} = 'cadastro/nova_conta.tt2';
}

=head2 cadastro_do

Efetua o cadastro/atualizacao do cliente.

=cut

sub cadastro_do : Local {
	my ($self, $c) = @_;

	# Parâmetros
	my $p = $c->request->params;
	
	# Checa o CPF/CNPJ
	$p->{doc} = undef if (((test_id('cpf', $p->{doc})) || (test_id('cnpj', $p->{doc}))) == 0);
	
	# Efetua o cadastro
	my $dados = {
		uid				=> $p->{uid}									|| -1,
		id_grupo		=> 3,
		id_situacao		=> 1,
		nome			=> $p->{nome}									|| undef,
		doc				=> $p->{doc}									|| undef,
		data_nascimento	=> &EasyCat::data2sql($p->{data_nascimento})	|| undef,
		endereco		=> $p->{endereco}								|| undef,
		bairro			=> $p->{bairro}									|| undef,
		cep				=> $p->{cep}									|| undef,
		telefone		=> $p->{telefone}								|| undef,
		observacao		=> $p->{observacao}								|| undef,
		kit_proprio		=> $p->{kit_proprio}							|| 0,
		cabo			=> $p->{cabo}									|| undef,
		valor_instalacao => $p->{valor_instalacao}						|| undef,
		valor_mensalidade => $p->{valor_mensalidade}					|| undef,
	};
	
	# O usuário admin pode escolher o grupo e a situação
	if ($c->check_any_user_role('admin')) {
		$dados->{id_grupo} = $p->{grupo};
		$dados->{id_situacao} = $p->{situacao};
	}
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(nome doc data_nascimento endereco bairro cep telefone cabo valor_instalacao valor_mensalidade)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{cliente} = $dados;
		$c->forward($p->{acao} . '/' . $p->{uid});
		return;
	}

	# Faz as devidas inserções no banco de dados
	my $cliente = undef;
	
	eval {
		# Cria novo usuário
		if ($p->{acao} eq 'novo') {
			$cliente = $c->model('RG3WifiDB::Usuarios')->create($dados);
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
			
			$cliente->update($dados);
		}
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar cliente: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Atualiza o coluna de grupo das contas e as tabelas do PPPoE
	foreach my $conta ($cliente->contas) {
		$conta->update({id_grupo => $cliente->id_grupo});
	}
	&radius_user_update($c, $cliente);
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Cliente cadastrado/editado com sucesso.';
	$c->forward('lista');
}

=head2 cadastro_conta_do

Efetua o cadastro/atualizacao de conta PPPoE.

=cut

sub cadastro_conta_do : Local {
	my ($self, $c) = @_;

	# Parâmetros
	my $p = $c->request->params;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $p->{cliente}})->first;
	
	# Efetua o cadastro
	my $dados = {
		uid				=> $p->{uid}					|| -1,
		id_cliente		=> $cliente->uid				|| undef,
		login			=> $p->{login}					|| undef,
		ip				=> '',
		id_plano		=> $p->{plano}					|| undef,
		id_grupo		=> $cliente->id_grupo			|| 3,
	};

	# Verifica se vai alterar a senha
	if ($p->{pwd1}) {
		$dados->{senha} = $p->{pwd1}
	};
		
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(login id_plano)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{conta} = $dados;
		$c->forward('nova_conta');
		return;
	}
	
	# Verifica as senhas
	if ($p->{pwd1} ne $p->{pwd2}) {
		$c->stash->{error_msg} = 'As senhas digitadas não coincidem.';
		$dados->{senha} = '';
		$c->stash->{conta} = $dados;
		$c->forward('nova_conta/' . $cliente->uid);
		return;
	}

	# Faz as devidas inserções no banco de dados
	eval {
		# Cria nova conta
		$c->model('RG3WifiDB::Contas')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar conta PPPoE: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Atualiza as tabelas do PPPoE
	&radius_user_update($c, $cliente);
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Conta PPPoE cadastrado/editado com sucesso.';
	$c->forward('editar/' . $cliente->uid);
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

	$c->stash->{cliente} = $cliente unless $c->stash->{cliente};
	$c->stash->{planos} = [$c->model('RG3WifiDB::Planos')->all];
	$c->stash->{grupos} = [$c->model('RG3WifiDB::Grupos')->all];
	$c->stash->{situacoes} = [$c->model('RG3WifiDB::UsuariosSituacao')->all];
	$c->stash->{acao} = 'editar';
	$c->stash->{template} = 'cadastro/novo.tt2';
}

=head2 editar_conta

Exibe página para edição de conta PPPoE.

=cut

sub editar_conta : Local {
	my ($self, $c, $uid) = @_;

	my $conta = $c->model('RG3WifiDB::Contas')->search({uid => $uid})->first;

	# Verifica permissões
	if (($conta->grupo->nome eq 'admin') && (!$c->check_user_roles('admin'))) {
		$c->stash->{error_msg} = 'Você não tem permissão para editar um administrador!';
		$c->forward('lista');
		return;
	}

	$c->stash->{conta} = $conta;
	$c->stash->{cliente} = $conta->id_cliente;
	$c->stash->{planos} = [$c->model('RG3WifiDB::Planos')->all];
	$c->stash->{acao} = 'editar';
	$c->stash->{template} = 'cadastro/nova_conta.tt2';
}

=head2 excluir

Exclui um usuário do sistema.

=cut

sub excluir : Local {
	my ($self, $c, $uid) = @_;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	
	foreach my $conta ($cliente->contas) {
		&user_del($c, $conta->uid);
	}
	
	$cliente->delete();
	$c->stash->{status_msg} = 'Cliente excluído com sucesso.';
	$c->forward('lista');
}

=head2 excluir_conta

Exclui uma conta PPPoE

=cut

sub excluir_conta : Local {
	my ($self, $c, $uid) = @_;
	my $conta = $c->model('RG3WifiDB::Contas')->search({uid => $uid})->first;
	&user_del($c, $conta->uid);
	$conta->delete();
	$c->stash->{status_msg} = 'Conta excluída com sucesso.';
	$c->forward('lista');
}

=head2 aviso_do

Coloca o cliente na lista de aviso de falta de pagamento.

=cut

sub aviso_do : Local {
	my ($self, $c, $uid) = @_;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	$cliente->update({aviso => 1});
	$c->stash->{status_msg} = 'O cliente foi adicionado na lista de aviso de falta de pagamento.';
	&radius_user_update($c, $cliente);
	$c->forward('lista');
}

=head2 aviso_undo

Retira o cliente da lista de aviso de falta de pagamento.

=cut

sub aviso_undo : Local {
	my ($self, $c, $uid) = @_;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	$cliente->update({aviso => 0});
	$c->stash->{status_msg} = 'O cliente foi removido da lista de aviso de falta de pagamento.';
	&radius_user_update($c, $cliente);
	$c->forward('lista');
}

=head2 bloqueio_do

Coloca o cliente na lista de bloqueio.

=cut

sub bloqueio_do : Local {
	my ($self, $c, $uid) = @_;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	$cliente->update({bloqueado => 1});
	&radius_user_update($c, $cliente);
	$c->stash->{status_msg} = 'O cliente foi bloqueado.';
	$c->forward('lista');
}

=head2 bloqueio_undo

Retira o cliente da lista de bloqueio.

=cut

sub bloqueio_undo : Local {
	my ($self, $c, $uid) = @_;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	$cliente->update({bloqueado => 0, aviso => 0});
	&radius_user_update($c, $cliente);
	$c->stash->{status_msg} = 'O cliente foi removido da lista de bloqueio e da lista de aviso.';
	$c->forward('lista');
}

=head2 exportar

Exporta a lista de clientes para o OBBPlus.

=cut

sub exportar : Local {
	my ($self, $c) = @_;
	
	my $saida = undef;
	
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->all) {
		# Remove formatação do CPF ou CNPJ
		my $doc = $cliente->doc;
		$doc =~ s/\.//g;
		$doc =~ s/\-//g;
		$doc =~ s/\///g;
		if (length($doc) == 14) {
			$doc = 'J' . abs($doc);
		} else {
			$doc = 'F' . abs($doc);
		}
		
		# Remove formatação do CEP também
		my $cep = $cliente->cep;
		$cep =~ s/\.//g;
		$cep =~ s/\-//g;
		
		# Inclui na variável
		$saida .= sprintf("%-15.15s%-15.15s%-40.40s%-52.52s%-63.63s%-30.30s%-30.30s%-2.2s%-8.8s%s\n",
			unac_string('utf-8', $cliente->uid),
			$doc,
			unac_string('utf-8', $cliente->nome),
			'0',
			unac_string('utf-8', $cliente->endereco),
			unac_string('utf-8', $cliente->bairro),
			'Feira de Santana',
			'BA',
			$cep,
			'00000000 000000000000 000000 ');
	}
	
	$c->stash->{saida} = $saida;
	$c->stash->{template} = 'cadastro/exportacao.tt2';
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
