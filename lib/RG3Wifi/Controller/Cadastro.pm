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
use Chart::Pie;
use Chart::Bars;

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

=head2 verifica_inadimplencia

Verifica se um cliente está inadimplente.

=cut

sub verifica_inadimplencia : Private {
	my ($c, $cliente) = @_;
	
	# Os usuários com mais de 15 dias de atraso são inadimplentes
	my $segundos = 15 * 24 * 60 * 60;
	my (@data_limite) = localtime(time - $segundos);
	my $datasql = &EasyCat::data2sql($data_limite[3] . '/' . abs($data_limite[4] + 1) . '/' . $data_limite[5]);
	
	# Retorna a lista de faturas em aberto
	return $c->model('RG3WifiDB::Faturas')->search({id_cliente => $cliente->uid, data_vencimento => {'<', $datasql}, id_situacao => 1});
}

=head2 atualiza_inadimplencia

Verifica se um cliente está inadimplente e atualiza seu estado.

=cut

sub atualiza_inadimplencia : Private {
	my ($c, $id_cliente) = @_;
	
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $id_cliente})->first;
	my @faturas = &verifica_inadimplencia($c, $cliente);
	
	if ($cliente) {
		if (@faturas > 0) {
			$cliente->update({inadimplente => 1});
		} else {
			$cliente->update({inadimplente => 0});
		}
	}
	
	# Retorna as faturas em aberto, assim como o verifica_inadimplencia()
	return @faturas;
}

=head2 radius_user_update

Atualiza cliente PPPoE no RADIUS (adiciona ou remove de acordo com situação e outros estados).

=cut

sub radius_user_update : Private {
	my ($c, $cliente) = @_;
	
	# Se estiver ativo e desbloqueado, adiciona
	if (($cliente->id_situacao == 1 || $cliente->id_situacao == 4) && ($cliente->bloqueado == 0)) {
		foreach my $conta ($cliente->contas) {
			if ($conta->bloqueado == 0) {
				&user_add($c, $conta->uid);
			} else {
				&user_del($c, $conta->uid);
			}
		}
	# Caso contrário, remove
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
	
	# Pool de IP
	#my $pool = $conta->plano->pool_name;
	my $pool = 'pool_rg3';
	
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
	
	# Tabela radreply
	$c->model('RG3WifiDB::radreply')->create({
		UserName	=> $conta->login,
		Attribute	=> 'Plano',
		op			=> '=',
		Value		=> $conta->id_plano,
	});
	
	if ($conta->ip) {
		$c->model('RG3WifiDB::radreply')->create({
			UserName	=> $conta->login,
			Attribute	=> 'Framed-IP-Address',
			op			=> '=',
			Value		=> $conta->ip,
		});
	}
	
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
	$c->model('RG3WifiDB::radreply')->search({UserName => $conta->login})->delete_all();
	$c->model('RG3WifiDB::radusergroup')->search({UserName => $conta->login})->delete_all();
}

=head2 remake_users

Refaz a lista de usuários o PPPoE.

=cut

sub remake_users : Local {
	my ($self, $c) = @_;
	
	# Limpa os dados atuais
	$c->model('RG3WifiDB::radcheck')->delete_all();
	$c->model('RG3WifiDB::radreply')->delete_all();
	$c->model('RG3WifiDB::radusergroup')->delete_all();
	
	# Popula as tabelas
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->all) {
		&radius_user_update($c, $cliente);		
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Lista de usuários PPPoE refeita! Execute "/radios/mac_add_all" para adicionar os MACs dos rádios ao RADIUS.';
	$c->forward('lista');
}

=head2 limpa_pppoe

Limpa as conexões travadas do PPPoE.

=cut

sub limpa_pppoe : Local {
	my ($self, $c) = @_;
	$c->model('RG3WifiDB::radacct')->search({acctstoptime => undef})->delete_all();
	$c->stash->{status_msg} = 'As conexões travadas foram removidas.';
	$c->forward('lista/');
}

=head2 limpa_pppoe1

Limpa uma conexão específica.

=cut

sub limpa_pppoe1 : Local {
	my ($self, $c, $username, $uid) = @_;
	$c->model('RG3WifiDB::radacct')->search({username => $username, acctstoptime => undef})->delete_all();
	$c->stash->{status_msg} = 'As conexões travadas foram removidas.';
	$c->forward('/acesso/logs', [$uid]);
}

=head2 lista

Lista os clientes cadastrados.

=cut

sub lista : Local {
	my ($self, $c, $situacao, $pagina) = @_;
	$situacao = 1 unless $situacao;
	$pagina = 1 unless($pagina);
	my $clientes = $c->model('RG3WifiDB::Usuarios')->search({id_situacao => $situacao})->page($pagina);
	$c->stash->{clientes} = [$clientes->all];
	$c->stash->{paginas} = $clientes->pager->last_page;
	$c->stash->{total} = $clientes->pager->total_entries;
	$c->stash->{pagina} = $pagina;
	$c->stash->{situacao} = $situacao;
	$c->stash->{template} = 'cadastro/lista.tt2';
}

=head2 lista_doc

Lista os clientes com documentos inválidos.

=cut

sub lista_doc : Local {
	my ($self, $c) = @_;
	
	my @clientes;
	
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
			-between => [&EasyCat::data2sql($p->{data_inst1} . ' 00:00'), &EasyCat::data2sql($p->{data_inst2} . ' 23:59')]
		}}, {rows => undef})];
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
		nao_bloqueia	=> $p->{nao_bloqueia}							|| 0,
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
		vencimento		=> $p->{vencimento}								|| undef,
	};
	
	# O usuário admin pode escolher o grupo e a situação
	if ($c->check_any_user_role('admin')) {
		$dados->{id_grupo} = $p->{grupo};
		$dados->{id_situacao} = $p->{situacao};
	}
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(nome doc data_nascimento endereco bairro cep telefone cabo valor_instalacao valor_mensalidade vencimento)]}
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
		ip				=> $p->{ip}						|| undef,
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
	
	# Altera o parametro
	$_[2] = $conta->id_cliente;
	$c->forward('editar', $_[2]);
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
	$c->forward('lista', ['1']);
}

=head2 bloqueio_undo

Retira o cliente da lista de bloqueio.

=cut

sub bloqueio_undo : Local {
	my ($self, $c, $uid) = @_;
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;
	$cliente->update({bloqueado => 0});
	&radius_user_update($c, $cliente);
	$c->stash->{status_msg} = 'O cliente foi removido da lista de bloqueio.';
	$c->forward('lista', ['1']);
}

=head2 bloqueio_pppoe_do

Coloca uma conta PPPoE na lista de bloqueio.

=cut

sub bloqueio_pppoe_do : Local {
	my ($self, $c, $uid) = @_;
	my $conta = $c->model('RG3WifiDB::Contas')->search({uid => $uid})->first;
	$conta->update({bloqueado => 1});
	&radius_user_update($c, $conta->cliente);
	$c->stash->{status_msg} = 'A conta foi bloqueada.';
	$c->forward('editar', [$conta->id_cliente]);
}

=head2 bloqueio_pppoe_undo

Retira uma conta PPPoE da lista de bloqueio.

=cut

sub bloqueio_pppoe_undo : Local {
	my ($self, $c, $uid) = @_;
	my $conta = $c->model('RG3WifiDB::Contas')->search({uid => $uid})->first;
	$conta->update({bloqueado => 0});
	&radius_user_update($c, $conta->cliente);
	$c->stash->{status_msg} = 'A conta foi desbloqueada.';
	$c->forward('editar', [$conta->id_cliente]);
}

=head2 bloqueio_automatico

Faz o bloqueio automático dos clientes inadimplentes.

=cut

sub bloqueio_automatico : Local {
	my ($self, $c) = @_;
	
	my $i = 0;
	my $clientes_bloqueados;
	
	# Busca os clientes inadimplentes
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->search({id_situacao => 1, inadimplente => 1}, {rows => undef})) {
		# Bloqueia o cliente, a não ser que esteja marcado para não bloquear
		if (!$cliente->nao_bloqueia && !$cliente->bloqueado) {
			$cliente->update({bloqueado => 1});
			&radius_user_update($c, $cliente);
			$i++;
			$clientes_bloqueados .= $cliente->nome . '<br>';
		}
	}
	
	# Exibe a lista de clientes bloqueados
	$c->stash->{total} = $i;
	$c->stash->{clientes_bloqueados} = $clientes_bloqueados;
	$c->stash->{template} = 'cadastro/relatorio_bloqueio.tt2';
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

=head2 gerar_boletos

Exibe página para geração de boletos.

=cut

sub gerar_boletos : Local {
	my ($self, $c, $uid) = @_;
	$c->stash->{template} = 'cadastro/gerar_boletos.tt2';
}

=head2 gerar_boletos_do

Gera os boletos de todos os clientes ativos para o OBBPlus.

=cut

sub gerar_boletos_do : Local {
	my ($self, $c) = @_;
	
	my $saida = undef;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$p,
		{required => [qw(mes ano)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{p} = $p;
		#$c->forward($p->{acao} . '/' . $p->{uid});
		return;
	}
	
	# Gera a linha de boleto para cada cliente
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->search({id_situacao => 1})) {
		# Remove formatação do CPF, CNPJ, data e mensalidade
		my $doc = $cliente->doc;
		$doc =~ s/\.//g;
		$doc =~ s/\-//g;
		$doc =~ s/\///g;
		
		my (@data) = localtime();
		my $data_atual = abs($data[5] + 1900) . sprintf("%02s", $data[4]) . sprintf("%02s", $data[3]);
		my $data_venc = abs($data[5] + 1900) . sprintf("%02s", $p->{mes}) . sprintf("%02s", $cliente->vencimento);
		
		# Deve incluir as casas decimais
		my $mensalidade = sprintf("%.2f", $cliente->valor_mensalidade);
		$mensalidade =~ s/\.//g;
		$mensalidade =~ s/\,//g;
		
		# Inclui na variável
		$saida .= sprintf("%-10.10s%-11.11s%-15.15s%-15.15s%-1.1s%-2.2s%-1.1s%-3.3s%-25.25s%-80.80s%-80.80s%-80.80s%-80.80s%-8.8s%-8.8s%-8.8s%-8.8s%-17.17s%-17.17s%-6.6s%-6.6s%-6.6s%-6.6s%-6.6s%-40.40s%-45.45s\n",
			'NULL',									# Número do título
			' ',									# Nosso número
			$doc,									# Código do sacado (15)
			' ',									# Código do sacador avalista
			'E',									# Local de impressão
			'01',									# Espécie
			'0',									# Aceite do título
			'0',									# Prazo protesto
			' ',									# Número controle participante
			'Referente ao uso no mês ' . abs($p->{mes} - 1) . ' de ' . $p->{ano},
													# Mensagem 1
			' ',									# Mensagem 2
			' ',									# Mensagem 3
			' ',									# Mensagem 4
			$data_venc,								# Data de vencimento
			' ',									# Data do desconto
			$data_atual,							# Data do documento
			$data_atual,							# Data do processamento
			$mensalidade,							# Valor do titulo (sem vírgula)
			'0',									# Valor do abatimento
			'0',									# Percentual bonificação
			'0',									# Percentual desconto
			'0',									# Percentual IOF
			'1000',									# Percentual mora mes (1 %)
			'2000',									# Percentual multa (2 %)
			$cliente->nome,							# Nome do sacado
			' ');									# Nome do sacador avalista
	}
	
	$c->stash->{saida} = $saida;
	$c->stash->{template} = 'cadastro/exportacao.tt2';
}

=head2 gerar_planilha_do

Gera a planilha de pagamento.

=cut

sub gerar_planilha_do : Local {
	my ($self, $c) = @_;
	
	my $saida = ",\"Entrada e saída de faturas\"\n";
	$saida .= ",\"Mês:\"\n\n";
	$saida .= "\"\",\"Cliente\",\"Mens.\",\"Venc.\",\"Loja\",\"Banco\",\"Data pag.\",\"Observações\",\"Não pago\",\"Pago\"\n";
	
	# Gera a linha da planilha para cada cliente
	my $i = 5;
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->search({id_situacao => 1}, {rows => undef})) {
		# Formata mensalidade
		my $mensalidade = $cliente->valor_mensalidade;
		$mensalidade =~ s/\./,/g;
		
		# Inclui na variável
		$saida .= sprintf(",\"%s\",\"%s\",%d,,,,,=IF(AND(E$i=\"\";F$i=\"\");1;\"\"),=IF(OR(E$i<>\"\";F$i<>\"\");1;\"\")\n",
			$cliente->nome,							# Nome do cliente
			$mensalidade,							# Mensalidade do cliente
			$cliente->vencimento,					# Dia do vencimento
		);
		
		$i++;
	}
	
	# Adiciona a última linha com os totais
	my $total = $i - 1;
	$saida .= ",\"TOTAL\",=SUM(C5:C$total),,=SUM(E5:E$total),=SUM(F5:F$total),,,=SUM(I5:I$total),=SUM(J5:J$total)\n";
	
	$c->stash->{saida} = $saida;
	$c->stash->{template} = 'cadastro/planilha.tt2';
}

=head2 abrir_chamado

Abre um novo chamado com os dados deste cliente.

=cut

sub abrir_chamado : Local {
	my ($self, $c, $uid) = @_;

	# Busca os dados do cliente
	my $cliente = $c->model('RG3WifiDB::Usuarios')->search({uid => $uid})->first;

	# Preenche os campos do formulário de chamados
	my $dados = ({
		cliente		=> $cliente->nome								|| undef,
		endereco	=> $cliente->endereco . ', ' . $cliente->bairro	|| undef,
		telefone	=> $cliente->telefone							|| undef,
	});
	
	# Envia para o método de novo chamado
	$c->stash->{chamado} = $dados;
	$c->forward('/chamados/novo');
}

=head2 stats

Mostra as estatísticas de clientes.

=cut

sub stats : Local {
	my ($self, $c) = @_;
	
	# Lista de clientes ativos
	$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->search({id_situacao => 1}, {rows => undef})];
	
	# Tempo de conexao
	#$c->stash->{top10_tempo} = [$c->model('RG3WifiDB::radacct')->search(undef, {order_by => 'AcctSessionTime DESC', rows => 10})];
	
	# Download
	#$c->stash->{top10_down} = [$c->model('RG3WifiDB::radacct')->search(undef, {order_by => 'AcctOutputOctets DESC', rows => 10})];

	# Upload
	#$c->stash->{top10_up} = [$c->model('RG3WifiDB::radacct')->search(undef, {order_by => 'AcctInputOctets DESC', rows => 10})];

	# Exibe página
	$c->stash->{template} = 'cadastro/stats.tt2';
}

=head2 chart_mensalidade

Gera um gráfico das mensalidades.

=cut

sub chart_mensalidade : Local {
	my ($self, $c) = @_;
	
	# Primeiro, criamos os delimitadores de mensalidades
	my @grupos = (30, 40, 50, 75, 100, 150, 250, 350, 500, 1000, 1500, 2000);
	my @valores = ();
	my @legendas = ();
	
	# Pesquisamos no BD quantos clientes estão em cada grupo
	my ($v1, $v2) = undef;
	foreach my $grupo (@grupos) {
		$v1 = $v2 | 0;
		$v2 = $grupo;
		my $total = $c->model('RG3WifiDB::Usuarios')->count({id_situacao => 1, valor_mensalidade => {-between => [$v1 + 1, $v2]}}, {rows => undef});
		push(@legendas, "Ate R\$ $v2:");
		push(@valores, $total);
	}
	
	# Monta o gráfico
	my $grafico = Chart::Pie->new(800, 600);
	my @dados = (\@legendas, \@valores);
	$grafico->set(
		'title' => 'Usuarios por mensalidades',
		'sub_title' => 'Quantos usuarios pagam ate o valor X',
		'png_border' => 1,
	);
	$grafico->cgi_png(\@dados);
}

=head2 chart_planos

Gera um gráfico dos planos de acesso.

=cut

sub chart_planos : Local {
	my ($self, $c) = @_;
	
	# Primeiro, criamos os delimitadores de mensalidades
	my @grupos = ();
	my @valores = ();
	
	# Pesquisamos no BD quantos pontos em cada plano
	foreach my $plano ($c->model('RG3WifiDB::Planos')->all) {
		my $total = $c->model('RG3WifiDB::Contas')->count({id_plano => $plano->id, id_situacao => 1}, {join => 'cliente'});
		push(@grupos, $plano->nome . ':');
		push(@valores, $total);
	}
	
	# Monta o gráfico
	my $grafico = Chart::Pie->new(800, 600);
	my @dados = (\@grupos, \@valores);
	$grafico->set(
		'title' => 'Contas por planos de acesso',
		'sub_title' => 'Quantas contas estao inseridas em cada plano de acesso',
	);
	$grafico->cgi_png(\@dados);
}

=head2 chart_instalacoes

Gera um gráfico da quantidade de instalações por mês.

=cut

sub chart_instalacoes : Local {
	my ($self, $c) = @_;
	
	# Pesquisa no BD quantas instalações foram feitas no último ano
	my @grupos = ();
	my @valores = ();
	my @hora = localtime(time);
	my $mes_atual = $hora[4];
	my $ano_atual = $hora[5] + 1900;
	my @meses = qw( Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez );
	for (my $i = 11; $i >= 0; $i--) {
		my $mes = ($mes_atual - $i) % 12;
		my $ano = ($mes_atual - $i) >= 0 ? $ano_atual : $ano_atual - 1;
		my $data1 = $ano . '-' . abs($mes + 1) . '-01 00:00';
		my $data2 = $ano . '-' . abs($mes + 1) . '-31 23:59';
		my $total = $c->model('RG3WifiDB::Usuarios')->count({id_situacao => 1, data_adesao => {-between => [$data1, $data2]}}, {rows => undef});
		push(@grupos, "$meses[$mes]/$ano");
		push(@valores, $total);
	}
	
	# Monta o gráfico
	my $grafico = Chart::Bars->new(800, 600);
	my @dados = (\@grupos, \@valores);
	$grafico->set(
		'title' => 'Instalacoes por mes',
		'legend' => 'none',
		'include_zero' => 'true',
		'precision' => 0,
	);
	$grafico->cgi_png(\@dados);	
}

=head2 busca

Faz uma busca no sistema.

=cut

sub busca : Local {
	my ($self, $c) = @_;

	# Parâmetros
	my $p = $c->request->params;
	my $termo = $p->{termo};
	#my $termo_ua = unac_string('utf-8', $termo);
	my $termo_ua = $termo;
	
	# Efetua a busca
	$c->stash->{clientes} = [$c->model('RG3WifiDB::Usuarios')->search({
		-or => [
			nome => {'like', "%$termo%"},		nome => {'like', "%$termo_ua%"},
			endereco => {'like', "%$termo%"},	endereco => {'like', "%$termo_ua%"},
			bairro => {'like', "%$termo%"},		bairro => {'like', "%$termo_ua%"},
		],
	}, {rows => undef})];
	
	$c->stash->{termo} = $termo;
	$c->stash->{template} = 'cadastro/lista.tt2';
}

=head2 gerar_faturas

Exibe a tela para geração de faturas.

=cut

sub gerar_faturas : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = 'cadastro/gerar_faturas.tt2';
}

=head2 gerar_faturas_do

Gera as faturas para pagamento das mensalidades.

=cut

sub gerar_faturas_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	my $i = 0;
	
	# Cria uma fatura para cada cliente
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->search({id_situacao => 1}, {rows => undef})) {
		# Alguns valores
		my $vencimento = &EasyCat::data2sql($cliente->vencimento . '/' . $p->{mes} . '/' . $p->{ano});
		my (@data_atual) = localtime();
		my $descricao = 'Referente ao uso no mês ' . abs($p->{mes} - 1) . "/$p->{ano}";
		
		# Primeiro verifica se já existe uma fatura para este cliente neste mês
		my $busca = $c->model('RG3WifiDB::Faturas')->search({id_cliente => $cliente->uid, data_vencimento => $vencimento})->first;
		
		if (!$busca) {
			my $fatura = {
				id_cliente		=> $cliente->uid,
				data_lancamento	=> &EasyCat::data2sql($data_atual[3] . '/' . abs($data_atual[4] + 1) . '/' . $data_atual[5]),
				data_vencimento	=> $vencimento,
				descricao		=> $descricao,
				valor			=> $cliente->valor_mensalidade,
				id_situacao		=> 1,
			};
			
			# Faz as devidas inserções no banco de dados
			eval {
				# Cria nova fatura
				$c->model('RG3WifiDB::Faturas')->update_or_create($fatura);
				$i++;
			};
			
			if ($@) {
				$c->stash->{error_msg} = 'Erro ao criar uma fatura: ' . $@;
				$c->stash->{template} = 'erro.tt2';
				return;
			}
			
			# Atualiza a situação deste cliente
			&atualiza_inadimplencia($c, $cliente->uid);
		}
	}
	
	$c->stash->{status_msg} = "$i faturas geradas com sucesso!";
	$c->forward('lista/');
}

=head2 nova_fatura

Exibe a página para gerar uma fatura manualmente.

=cut

sub nova_fatura : Local {
	my ($self, $c, $uid) = @_;
	$c->stash->{fatura} = {id_cliente => $uid} unless $c->stash->{fatura};
	$c->stash->{template} = 'cadastro/nova_fatura.tt2';
}

=head2 editar_fatura

Exibe a página para editar uma fatura.

=cut

sub editar_fatura : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{fatura} = $c->model('RG3WifiDB::Faturas')->search({id => $id})->first;
	$c->forward('nova_fatura');
}

=head2 nova_fatura_do

Gerar uma nova fatura manualmente.

=cut

sub nova_fatura_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $fatura = {
		id				=> $p->{id}										|| -1,
		id_cliente		=> $p->{id_cliente}								|| undef,
		data_vencimento	=> &EasyCat::data2sql($p->{data_vencimento})	|| undef,
		valor			=> $p->{valor}									|| undef,
		descricao		=> $p->{descricao}								|| undef,
		id_situacao		=> 1,
	};
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$fatura,
		{required => [qw(id_cliente data_vencimento valor)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{fatura} = $fatura;
		$c->forward('nova_fatura');
		return;
	}
	
	# Faz as devidas inserções no banco de dados
	eval {
		# Gera fatura e atualiza a inadimplencia
		$c->model('RG3WifiDB::Faturas')->update_or_create($fatura);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao criar fatura: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Após criar a fatura, verifica se ainda existem faturas em aberto
	&atualiza_inadimplencia($c, $p->{id_cliente});

	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Fatura criada com sucesso.';
	$c->forward('editar/' . $p->{id_cliente});
}

=head2 liquidar_fatura

Exibe a página para liquidar uma fatura.

=cut

sub liquidar_fatura : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{fatura} = $c->model('RG3WifiDB::Faturas')->search({id => $id})->first unless $c->stash->{fatura};
	$c->stash->{template} = 'cadastro/liquidar_fatura.tt2';
}

=head2 liquidar_fatura_do

Liquida uma fatura.

=cut

sub liquidar_fatura_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $fatura = {
		id				=> $p->{id}										|| undef,
		data_liquidacao	=> &EasyCat::data2sql($p->{data_liquidacao})	|| undef,
		valor_pago		=> $p->{valor_pago}								|| undef,
		id_situacao		=> 2,
	};
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$fatura,
		{required => [qw(id)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{fatura} = $fatura;
		$c->forward('liquidar_fatura');
		return;
	}
	
	# Verifica se está liquidada
	if ($fatura->{valor_pago} == 0) {
		$fatura->{id_situacao} = 1;
		$fatura->{data_liquidacao} = undef;
		$fatura->{valor_pago} = undef;
	}

	# Faz as devidas inserções no banco de dados
	eval {
		# Liquida fatura
		$c->model('RG3WifiDB::Faturas')->update_or_create($fatura);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao liquidar fatura: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Após alterar a liquidação, verifica se ainda existem faturas em aberto
	&atualiza_inadimplencia($c, $p->{id_cliente});

	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Fatura liquidada com sucesso.';
	$c->forward('editar/' . $p->{id_cliente});
}

=head2 excluir_fatura

Exclui uma fatura.

=cut

sub excluir_fatura : Local {
	my ($self, $c, $id) = @_;
	my $fatura = $c->model('RG3WifiDB::Faturas')->search({id => $id})->first;
	$fatura->delete();
	$c->stash->{status_msg} = 'Fatura excluída com sucesso.';

	# Após excluir a fatura, verifica se ainda existem faturas em aberto
	&atualiza_inadimplencia($c, $fatura->id_cliente);
	
	# Altera o parametro
	$_[2] = $fatura->id_cliente;
	$c->forward('editar', $_[2]);
}

=head2 liquidacao_massa

Exibe uma lista com as faturas em aberto para liquidação em massa.

=cut

=head2 gerar_faturas

Exibe a tela para geração de faturas.

=cut

sub liquidacao_massa : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = 'cadastro/liquidacao_massa.tt2';
}

=head2 liquidacao_massa_lista

Exibe a lista para liquidação em massa.

=cut

sub liquidacao_massa_lista : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Filtro por data de vencimento
	$c->stash->{faturas} = [$c->model('RG3WifiDB::Faturas')->search({data_vencimento => {
		-between => [&EasyCat::data2sql($p->{inicio}), &EasyCat::data2sql($p->{fim})]
	}, 'me.id_situacao' => 1}, {join => 'cliente', order_by => 'cliente.nome ASC' })];

	# Pra facilitar, a data de pagamento já será preenchida com a data de ontem
	my $ontem = DateTime->now()->subtract(days => 1)->dmy('/');
	$c->stash->{ontem} = $ontem;
	$c->stash->{template} = 'cadastro/liquidacao_massa_do.tt2';
}

=head2 liquidacao_massa_do

Efetua a liquidação em massa.

=cut

sub liquidacao_massa_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;

	# Verifica quais as faturas foram marcadas
	for (my $i = 1; $i <= $p->{total}; $i++) {
		if ($p->{"fatura_$i"}) {
			# Liquida a fatura
			my $fatura = $c->model('RG3WifiDB::Faturas')->search({id => $p->{"fatura_$i"}})->first;
			if ($fatura && $p->{"data_pagamento_$i"} && $p->{"valor_pago_$i"}) {
				$fatura->update({
					id_situacao => 2,
					data_liquidacao => &EasyCat::data2sql($p->{"data_pagamento_$i"}),
					valor_pago => $p->{"valor_pago_$i"},
				});
				
				# Atualiza o cliente
				&atualiza_inadimplencia($c, $fatura->id_cliente);
			}
		}
	}
	
	# Pronto!
	$c->stash->{status_msg} = 'As faturas selecionadas foram liquidadas!';
	$c->forward('lista/');
}

=head2 lista_inadimplentes

Exibe uma lista com os dados dos inadimplentes.

=cut

sub lista_inadimplentes : Local {
	my ($self, $c) = @_;
	
	my @inadimplentes;
	
	foreach my $cliente ($c->model('RG3WifiDB::Usuarios')->search({}, {rows => undef})) {
		my @faturas = &atualiza_inadimplencia($c, $cliente->uid);
		next if (@faturas == 0);
		my $valor_total = 0;
		
		foreach my $fatura (@faturas) {
			$valor_total += $fatura->valor;
		}
		
		my $dados = {
			nome	=> $cliente->nome,
			telefone=> $cliente->telefone,
			total	=> scalar(@faturas),
			valor	=> $valor_total,
			id		=> $cliente->uid,
		};

		push(@inadimplentes, $dados);
	}
	
	$c->stash->{inadimplentes} = [@inadimplentes];
	$c->stash->{template} = 'cadastro/lista_inadimplentes.tt2';
}

=head2 lista_faturas_abertas

Lista os clientes com faturas em aberto.

=cut

sub lista_faturas_abertas : Local {
	# SQL:
	# select distinct(rg3_usuarios.uid) from rg3_usuarios,rg3_faturas where rg3_faturas.data_vencimento < NOW() and rg3_faturas.id_situacao = 1 and rg3_faturas.id_cliente = rg3_usuarios.uid;
	
	my ($self, $c) = @_;
	my @devedores;

	foreach my $fatura ($c->model('RG3WifiDB::Faturas')->search({'me.data_vencimento' => {'<', DateTime->now()->ymd('-')}, 'me.id_situacao' => 1},
		{join => 'cliente', order_by => 'cliente.nome ASC'})) {
		
		push(@devedores, $fatura->cliente);
	}
	
	$c->stash->{devedores} = [@devedores];
	$c->stash->{template} = 'cadastro/lista_devedores.tt2';

}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
