package RG3Wifi::Controller::Radios;

use strict;
use warnings;
use base 'Catalyst::Controller';
use FindBin;
use lib "$FindBin::Bin/../..";
use EasyCat;
use Data::FormValidator;
use Net::Ping::External qw(ping);

=head1 NAME

RG3Wifi::Controller::Radios - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
	my ($self, $c) = @_;
	$c->forward('form_busca');
}

=head2 access_denied

Handle Catalyst::Plugin::Authorization::ACL access denied exceptions

=cut

sub access_denied : Private {
	my ($self, $c) = @_;
	$c->stash->{error_msg} = 'Você não tem permissão para acessar este recurso.';
	$c->forward('RG3Wifi::Controller::Acesso', 'inicio');
}

=head2 mac_add

Adiciona um MAC no RADIUS.

=cut

sub mac_add : Private {
	my ($c, $mac) = @_;
	$mac =~ tr/a-z/A-Z/;
	
	if (@_ < 2) { return 1; }

	# Apaga MAC já existente
	&mac_del($c, $mac);
	
	# Tabela radcheck
	$c->model('RG3WifiDB::radcheck')->create({
		UserName	=> $mac,
		Attribute	=> 'Password',
		Value		=> $mac,
	});

	# Tabela radusergroup
	$c->model('RG3WifiDB::radusergroup')->create({
		username	=> $mac,
		groupname	=> 'radio',
	});
}

=head2 mac_del

Remove um MAC do RADIUS.

=cut

sub mac_del : Private {
	my ($c, $mac) = @_;
	$mac =~ tr/a-z/A-Z/;
	
	if (@_ < 2) { return 1; }
	
	$c->model('RG3WifiDB::radcheck')->search({UserName => $mac})->delete_all();
	$c->model('RG3WifiDB::radusergroup')->search({username => $mac})->delete_all();
}

=head2 mac_add_all

Adiciona os MACs de todos os rádios no RADIUS.

=cut

sub mac_add_all : Local {
	my ($self, $c) = @_;
	
	my $i = 0;
	
	# Para cada rádio, iremos verificar se o MAC é válido antes de adicionar
	foreach my $radio ($c->model('RG3WifiDB::Radios')->all) {
		if (&verifica_mac($radio->mac)) {
			&mac_add($c, uc($radio->mac));
			$i++;
		}
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = "$i MACs foram adicionados!";
	$c->forward('lista');
}

=head2 verifica_mac

Verifica se o MAC adicionado está na forma correta.

=cut

sub verifica_mac : Private {
	my ($mac) = @_;
	
	if ($mac !~ /^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$/) {
		return 0;
	} else {
		return 1;
	}
}

=head2 form_busca

Exibe o formulário de busca.

=cut

sub form_busca : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = 'radios/lista_radios_busca.tt2';
}

=head2 lista

Lista os rádios cadastrados.

=cut

sub lista : Local {
	my ($self, $c) = @_;
	$c->stash->{bases} = [$c->model('RG3WifiDB::Radios')->search({id_tipo => 2})];
	$c->stash->{template} = 'radios/lista_radios.tt2';
}

=head2 lista_mods

Lista os fabricantes e modelos cadastrados.

=cut

sub lista_mods : Local {
	my ($self, $c) = @_;
	$c->stash->{fabricantes} = [$c->model('RG3WifiDB::Fabricantes')->all];
	$c->stash->{modelos} = [$c->model('RG3WifiDB::Modelos')->all];
	$c->stash->{template} = 'radios/lista_modelos.tt2';
}

=head2 novo_fab

Exibe formulário de cadastro de fabricantes.

=cut

sub novo_fab : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = 'radios/novo_fabricante.tt2';
}

=head2 novo_mod

Exibe formulário de cadastro de modelos.

=cut

sub novo_mod : Local {
	my ($self, $c) = @_;
	$c->stash->{fabricantes} = [$c->model('RG3WifiDB::Fabricantes')->all];
	$c->stash->{template} = 'radios/novo_modelo.tt2';
}

=head2 novo_rad

Exibe formulário de cadastro de rádios.

=cut

sub novo_rad : Local {
	my ($self, $c) = @_;
	$c->stash->{modelos} = [$c->model('RG3WifiDB::Modelos')->all];
	$c->stash->{bases} = [$c->model('RG3WifiDB::Radios')->search({id_tipo => 2})];
	$c->stash->{tipos} = [$c->model('RG3WifiDB::RadiosTipo')->all];
	$c->stash->{bandas} = [$c->model('RG3WifiDB::RadiosBanda')->all];
	$c->stash->{template} = 'radios/novo_radio.tt2';
}

=head2 novo_fab_do

Efetua o cadastro de um novo fabricante.

=cut

sub novo_fab_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id   => $p->{id}   || -1,
		nome => $p->{nome} || undef,
	});

	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(nome)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{fabricante} = $dados;
		$c->forward('novo_fab');
		return;
	}

	# Atualiza o banco
	eval {
		$c->model('RG3WifiDB::Fabricantes')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar fabricante: ' . $@;
		$c->stash->{template} = 'error.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Fabricante cadastrado com sucesso.';
	$c->forward('lista_mods');
}

=head2 novo_mod_do

Efetua o cadastro de um novo modelo.

=cut

sub novo_mod_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id				=> $p->{id}				|| -1,
		id_fabricante	=> $p->{fabricante}		|| undef,
		nome			=> $p->{nome}			|| undef,
	});
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(id_fabricante nome)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{modelo} = $dados;
		$c->forward('novo_mod');
		return;
	}

	# Atualiza o banco
	eval {
		$c->model('RG3WifiDB::Modelos')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar modelo: ' . $@;
		$c->stash->{template} = 'error.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Modelo cadastrado com sucesso.';
	$c->forward('lista_mods');
}

=head2 novo_rad_do

Efetua o cadastro de um novo rádio.

=cut

sub novo_rad_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id				=> $p->{id}									|| -1,
		id_modelo		=> $p->{modelo}								|| undef,
		id_base			=> $p->{base}								|| undef,
		id_tipo			=> $p->{tipo}								|| undef,
		mac				=> uc($p->{mac})							|| undef,
		comodato		=> $p->{comodato}							|| 0,
		data_instalacao	=> &EasyCat::data2sql($p->{data_instalacao})|| undef,
		localizacao		=> $p->{localizacao}						|| undef,
		id_banda		=> $p->{banda}								|| undef,
		ip				=> $p->{ip}									|| undef,
		essid			=> $p->{essid}								|| undef,
	});
	
	# Rádio não instalado e rádio base
	if ($dados->{id_tipo} == 2) {
		$dados->{id_base} = undef;
	} else {
		$dados->{essid} = undef;
	}
	
	# Verifica o formato do MAC
	unless(&verifica_mac($dados->{mac})) { $dados->{mac} = undef; }
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(id_modelo id_tipo mac)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{radio} = $dados;
		$c->forward('novo_rad');
		return;
	}

	# Atualiza o banco
	eval {
		$c->model('RG3WifiDB::Radios')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar rádio: ' . $@;
		$c->stash->{template} = 'error.tt2';
		return;
	}
	
	# Cadastra o MAC na autenticação via RADIUS
	&mac_add($c, $dados->{mac});
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Rádio cadastrado com sucesso.';
	$c->forward('lista');
}

=head2 excluir_fab

Exclui um fabricante.

=cut

sub excluir_fab : Local {
	my ($self, $c, $id) = @_;
	$c->model('RG3WifiDB::Fabricantes')->search({id => $id})->delete_all();
	$c->stash->{status_msg} = 'Fabricante excluído!';
	$c->forward('lista_mods');
}

=head2 excluir_mod

Exclui um modelo.

=cut

sub excluir_mod : Local {
	my ($self, $c, $id) = @_;
	$c->model('RG3WifiDB::Modelos')->search({id => $id})->delete_all();
	$c->stash->{status_msg} = 'Modelo excluído!';
	$c->forward('lista_mods');
}

=head2 excluir_rad

Exclui um rádio.

=cut

sub excluir_rad : Local {
	my ($self, $c, $id) = @_;
	$c->model('RG3WifiDB::Radios')->search({id => $id})->delete_all();
	$c->stash->{status_msg} = 'Rádio excluído!';
	$c->forward('lista');
}

=head2 editar_fab

Exibe formulário para editar fabricante.

=cut

sub editar_fab : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{fabricante} = $c->model('RG3WifiDB::Fabricantes')->search({id => $id})->first;
	$c->stash->{acao} = 'editar';
	$c->forward('novo_fab');
}

=head2 editar_mod

Exibe formulário para editar modelo.

=cut

sub editar_mod : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{modelo} = $c->model('RG3WifiDB::Modelos')->search({id => $id})->first;
	$c->stash->{acao} = 'editar';
	$c->forward('novo_mod');
}

=head2 editar_rad

Exibe formulário para editar rádio.

=cut

sub editar_rad : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{radio} = $c->model('RG3WifiDB::Radios')->search({id => $id})->first;
	$c->stash->{acao} = 'editar';
	$c->forward('novo_rad');
}

=head2 teste_rad

Exibe formulário para testar rádio.

=cut

sub teste_rad : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = 'radios/teste.tt2';
}

=head2 teste_rad_do

Efetua o teste de todos os rádios.

=cut

sub teste_rad_do : Local {
	my ($self, $c) = @_;
	
	my $count = $c->request->params->{count} || 5;
	my $size = $c->request->params->{size} || 56;
	my @resultado = undef;

	foreach my $radio ($c->model('RG3WifiDB::Radios')->all) {
		my $host = $radio->ip;
		next unless ($host);

		# Efetua o teste
		print "Testando " . $radio->ip . "...\n";	# Apache Keep-alive
		my $alive = ping(host => $radio->ip);

		my $teste = ({
			falhou	=> !$alive,
			radio	=> $radio,
		});
		
		push(@resultado, $teste);
	}
	
	$c->stash->{resultado} = [@resultado];
	$c->stash->{quantidade} = $count;
	$c->stash->{tamanho} = $size;
	$c->forward('teste_rad');
}

=head2 teste1_rad_do

Efetua o teste de um rádio específico.

=cut

sub teste1_rad_do : Local {
	my ($self, $c, $id) = @_;
	
	# Pega os dados do rádio
	my $radio = $c->model('RG3WifiDB::Radios')->search({id => $id})->first;
	if (!$radio) {
		$c->stash->{error_msg} = 'Rádio inexistente!';
		$c->forward('lista');
		return;
	}
	
	# Efetua o teste
	my $alive = ping(host => $radio->ip);
	
	# Exibe o resultado
	if (!$alive) {
		$c->stash->{falhou} = 1;
	}
	$c->stash->{radio} = $radio;
	$c->stash->{template} = 'radios/teste1.tt2';
}

=head2 busca

Faz uma busca na lista de rádios.

=cut

sub busca : Local {
	my ($self, $c) = @_;

	# Parâmetros
	my $p = $c->request->params;
	my $termo = $p->{termo};
	#my $termo_ua = unac_string('utf-8', $termo);
	my $termo_ua = $termo;
	
	# Efetua a busca
	$c->stash->{radios} = [$c->model('RG3WifiDB::Radios')->search({
		-or => [
			mac => {'like', "%$termo%"},			mac => {'like', "%$termo_ua%"},
			localizacao => {'like', "%$termo%"},	localizacao => {'like', "%$termo_ua%"},
			ip => {'like', "%$termo%"},				ip => {'like', "%$termo_ua%"},
			essid => {'like', "%$termo%"},			essid => {'like', "%$termo_ua%"},
		],
	}, {rows => undef})];
	
	$c->stash->{termo} = $termo;
	$c->stash->{template} = 'radios/lista_radios_busca.tt2';
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
