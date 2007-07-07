package RG3Wifi::Controller::Radios;

use strict;
use warnings;
use base 'Catalyst::Controller';

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

=head2 lista

Lista os rádios cadastrados.

=cut

sub lista : Local {
	my ($self, $c) = @_;
	$c->stash->{bases} = [$c->model('RG3WifiDB::Radios')->search({id_tipo => 1})];
	$c->stash->{fabricantes} = [$c->model('RG3WifiDB::Fabricantes')->all];
	$c->stash->{modelos} = [$c->model('RG3WifiDB::Modelos')->all];
	$c->stash->{template} = 'radios/lista.tt2';
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
	$c->stash->{fabricantes} = [$c->model('RG3WifiDB::Fabricantes')->all];
	$c->stash->{modelos} = [$c->model('RG3WifiDB::Modelos')->all];
	$c->stash->{bases} = [$c->model('RG3WifiDB::Radios')->search({id_tipo => 1})];
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
		nome => $p->{nome} || undef,
	});

	eval {
		if ($p->{'acao'} eq 'editar') {
			my $fabricante = $c->model('RG3WifiDB::Fabricantes')->search({id => $p->{id}})->first;
			$fabricante->update($dados);
		} else {
			my $fabricante = $c->model('RG3WifiDB::Fabricantes')->create($dados);
		}
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar fabricante: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Fabricante cadastrado com sucesso.';
	$c->forward('novo_fab');
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
		id_fabricante	=> $p->{fabricante}		|| undef,
		nome			=> $p->{nome}			|| undef,
	});
	
	eval {
		if ($p->{'acao'} eq 'editar') {
			my $modelo = $c->model('RG3WifiDB::Modelos')->search({id => $p->{id}})->first;
			$modelo->update($dados);
		} else {
			my $modelo = $c->model('RG3WifiDB::Modelos')->create($dados);
		}
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar modelo: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Modelo cadastrado com sucesso.';
	$c->forward('novo_mod');
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
		id_modelo		=> $p->{modelo}			|| undef,
		id_base			=> $p->{base}			|| undef,
		id_tipo			=> $p->{tipo}			|| undef,
		mac				=> $p->{mac}			|| undef,
		data_compra		=> $p->{data_compra}	|| undef,
		data_instalacao	=> $p->{data_instalacao}|| undef,
		valor_compra	=> $p->{valor_compra}	|| undef,
		custo			=> $p->{custo}			|| undef,
		localizacao		=> $p->{localizacao}	|| undef,
		id_banda		=> $p->{banda}			|| undef,
		id_preambulo	=> $p->{preambulo}		|| undef,
		ip				=> $p->{ip}				|| undef,
		essid			=> $p->{essid}			|| undef,
	});
	
	eval {
		if ($p->{'acao'} eq 'editar') {
			my $radio = $c->model('RG3WifiDB::Radios')->search({id => $p->{id}})->first;
			$radio->update($dados);
		} else {
			my $radio = $c->model('RG3WifiDB::Radios')->create($dados);
		}
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar rádio: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Rádio cadastrado com sucesso.';
	$c->forward('novo_rad');
}

=head2 editar_fab

Exibe formulário para editar fabricante.

=cut

sub editar_fab : Local {
	my ($self, $c, $id) = @_;
	
	# Busca fabricante
	my $fabricante = $c->model('RG3WifiDB::Fabricantes')->search({id => $id})->first;
	$c->stash->{fabricante} = $fabricante;
	$c->stash->{acao} = 'editar';
	$c->forward('novo_fab');
}

=head2 editar_mod

Exibe formulário para editar modelo.

=cut

sub editar_mod : Local {
	my ($self, $c, $id) = @_;
	
	# Busca modelo
	my $modelo = $c->model('RG3WifiDB::Modelos')->search({id => $id})->first;
	$c->stash->{modelo} = $modelo;
	$c->stash->{acao} = 'editar';
	$c->forward('novo_mod');
}

=head2 editar_rad

Exibe formulário para editar rádio.

=cut

sub editar_rad : Local {
	my ($self, $c, $id) = @_;
	
	# Busca rádio
	my $radio = $c->model('RG3WifiDB::Radios')->search({id => $id})->first;
	$c->stash->{radio} = $radio;
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
