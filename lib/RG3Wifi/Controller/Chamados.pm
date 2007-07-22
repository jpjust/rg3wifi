package RG3Wifi::Controller::Chamados;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::FormValidator;

=head1 NAME

RG3Wifi::Controller::Chamados - Catalyst Controller

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

Lista os chamados abertos.

=cut

sub lista : Local {
	my ($self, $c) = @_;
	my $estado = $c->model('RG3WifiDB::ChamadosEstado')->search({id => 1})->first;
	$c->stash->{suportes} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 1, id_estado => $estado->id})];
	$c->stash->{estudos} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 2, id_estado => $estado->id})];
	$c->stash->{instalacoes} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 3, id_estado => $estado->id})];
	$c->stash->{estado} = $estado;
	$c->stash->{template} = 'chamados/lista.tt2';
}

=head2 lista_ok

Lista os chamados finalizados.

=cut

sub lista_ok : Local {
	my ($self, $c) = @_;
	my $estado = $c->model('RG3WifiDB::ChamadosEstado')->search({id => 2})->first;
	$c->stash->{suportes} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 1, id_estado => $estado->id})];
	$c->stash->{estudos} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 2, id_estado => $estado->id})];
	$c->stash->{instalacoes} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 3, id_estado => $estado->id})];
	$c->stash->{estado} = $estado;
	$c->stash->{template} = 'chamados/lista.tt2';
}

=head2 novo

Exibe formulário de abertura de chamado.

=cut

sub novo : Local {
	my ($self, $c) = @_;
	$c->stash->{tipos} = [$c->model('RG3WifiDB::ChamadosTipo')->all];
	$c->stash->{acao} = 'novo';
	$c->stash->{estado} = 1;
	$c->stash->{template} = 'chamados/novo.tt2';
}

=head2 novo_do

Efetua o cadastro de um novo chamado.

=cut

sub novo_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id				=> $p->{id}									|| undef,
		id_tipo			=> $p->{tipo}								|| undef,
		id_estado		=> $p->{estado}								|| undef,
		cliente			=> $p->{cliente}							|| undef,
		data_chamado	=> &RG3Wifi::data2sql($p->{data_chamado})	|| undef,
		data_conclusao	=> &RG3Wifi::data2sql($p->{data_conclusao})	|| undef,
		endereco		=> $p->{endereco}							|| undef,
		telefone		=> $p->{telefone}							|| undef,
		motivo			=> $p->{motivo}								|| undef,
		observacoes		=> $p->{observacoes}						|| undef,
	});
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(id_tipo id_estado cliente data_chamado endereco motivo)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{chamado} = $dados;
		$c->forward('novo');
		return;
	}

	# Atualiza o banco
	eval {
		my $chamado = $c->model('RG3WifiDB::Chamados')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao cadastrar/editar chamado: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Chamado cadastrado/editado com sucesso.';
	$c->forward('lista');
}

=head2 excluir

Exclui um chamado.

=cut

sub excluir : Local {
	my ($self, $c, $id) = @_;
	
	my $chamado = $c->model('RG3WifiDB::Chamados')->search({id => $id})->first;
	if ($chamado) {
		$chamado->delete();
		$c->stash->{status_msg} = 'Chamado excluído!';
	} else {
		$c->stash->{error_msg} = 'Chamado não encontrado!';
	}
	
	$c->forward('lista');
}

=head2 editar

Exibe formulário de edição de chamado.

=cut

sub editar : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{tipos} = [$c->model('RG3WifiDB::ChamadosTipo')->all];
	$c->stash->{chamado} = $c->model('RG3WifiDB::Chamados')->search({id => $id})->first;
	$c->stash->{acao} = 'editar';
	$c->stash->{estado} = 1;
	$c->stash->{template} = 'chamados/novo.tt2';
}

=head2 finalizar

Exibe formulário de finalização de chamado.

=cut

sub finalizar : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{tipos} = [$c->model('RG3WifiDB::ChamadosTipo')->all];
	$c->stash->{chamado} = $c->model('RG3WifiDB::Chamados')->search({id => $id})->first;
	$c->stash->{acao} = 'finalizar';
	$c->stash->{estado} = 2;
	$c->stash->{template} = 'chamados/novo.tt2';
}


=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
