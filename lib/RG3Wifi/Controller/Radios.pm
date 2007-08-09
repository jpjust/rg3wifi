package RG3Wifi::Controller::Radios;

use strict;
use warnings;
use base 'Catalyst::Controller';
use EasyCat;
use Data::FormValidator;

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

=head2 lista

Lista os rádios cadastrados.

=cut

sub lista : Local {
	my ($self, $c) = @_;
	$c->stash->{bases} = [$c->model('RG3WifiDB::Radios')->search({id_tipo => 2})];
	$c->stash->{radiosloja} = [$c->model('RG3WifiDB::Radios')->search({id_tipo => 1})];
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
	$c->stash->{preambulos} = [$c->model('RG3WifiDB::RadiosPreambulo')->all];
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
		$c->stash->{template} = 'erro.tt2';
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
		$c->stash->{template} = 'erro.tt2';
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
		mac				=> $p->{mac}								|| undef,
		data_compra		=> &EasyCat::data2sql($p->{data_compra})	|| undef,
		data_instalacao	=> &EasyCat::data2sql($p->{data_instalacao})|| undef,
		valor_compra	=> $p->{valor_compra}						|| undef,
		custo			=> $p->{custo}								|| undef,
		localizacao		=> $p->{localizacao}						|| undef,
		id_banda		=> $p->{banda}								|| undef,
		id_preambulo	=> $p->{preambulo}							|| undef,
		ip				=> $p->{ip}									|| undef,
		essid			=> $p->{essid}								|| undef,
	});
	
	# Rádio não instalado e rádio base
	if ($dados->{id_tipo} == 1) {
		$dados->{id_base} = undef;
		$dados->{data_instalacao} = undef;
		$dados->{localizacao} = undef;
		$dados->{essid} = undef;
	} elsif ($dados->{id_tipo} == 2) {
		$dados->{id_base} = undef;
	} else {
		$dados->{essid} = undef;
	}
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(id_modelo id_tipo mac data_compra valor_compra custo)]}
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
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
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


=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
