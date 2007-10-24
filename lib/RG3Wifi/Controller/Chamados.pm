package RG3Wifi::Controller::Chamados;

use strict;
use warnings;
use base 'Catalyst::Controller';
use FindBin;
use lib "$FindBin::Bin/../..";
use EasyCat;
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

=head2 access_denied

Handle Catalyst::Plugin::Authorization::ACL access denied exceptions

=cut

sub access_denied : Private {
	my ($self, $c) = @_;
	$c->stash->{error_msg} = 'Você não tem permissão para acessar este recurso.';
	$c->forward('lista');
}

=head2 lista

Lista os chamados.

=cut

sub lista : Local {
	my ($self, $c) = @_;
	$c->stash->{estados} = [$c->model('RG3WifiDB::ChamadosEstado')->all];
	$c->stash->{tipos} = [$c->model('RG3WifiDB::ChamadosTipo')->all];
	$c->stash->{estado_atual} = $c->request->params->{estado} || 1;
	$c->stash->{template} = 'chamados/lista.tt2';
}

=head2 lista_p

Lista os chamados abertos para impressão.

=cut

sub lista_p : Local {
	my ($self, $c, $tipo, $estado) = @_;
	$c->stash->{tipo} = $c->model('RG3WifiDB::ChamadosTipo')->search({id => $tipo})->first;
	$c->stash->{chamados} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => $tipo, id_estado => $estado})];
	$c->stash->{template} = 'chamados/papel.tt2';
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
		id				=> $p->{id}									|| -1,
		id_tipo			=> $p->{tipo}								|| undef,
		id_estado		=> $p->{estado}								|| undef,
		cliente			=> $p->{cliente}							|| undef,
		data_chamado	=> &EasyCat::data2sql($p->{data_chamado})	|| undef,
		data_conclusao	=> &EasyCat::data2sql($p->{data_conclusao})	|| undef,
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
		$c->model('RG3WifiDB::Chamados')->update_or_create($dados);
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
	$c->model('RG3WifiDB::Chamados')->search({id => $id})->delete_all();
	$c->stash->{status_msg} = 'Chamado excluído!';
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
	$c->stash->{estado} = $c->stash->{chamado}->id_estado;
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

=head2 detalhes

Exibe detalhes do chamado.

=cut

sub detalhes : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{chamado} = $c->model('RG3WifiDB::Chamados')->search({id => $id})->first;
	$c->stash->{template} = 'chamados/detalhes.tt2';
}


=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
