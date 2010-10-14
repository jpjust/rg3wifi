package RG3Wifi::Controller::Chamados;

use strict;
use warnings;
use base 'Catalyst::Controller';
use FindBin;
use lib "$FindBin::Bin/../..";
use EasyCat;
use Data::FormValidator;
use Chart::Bars;

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
	$c->forward('RG3Wifi::Controller::Acesso', 'inicio');
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

=head2 chart_suporte

Gera um gráfico da quantidade de instalações por mês.

=cut

sub chart_suporte : Local {
	my ($self, $c) = @_;
	
	# Pesquisa no BD quantos chamados de suporte foram feitos no último ano
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
		my $total = $c->model('RG3WifiDB::Chamados')->count({id_tipo => 1, data_chamado => {-between => [$data1, $data2]}});
		push(@grupos, "$meses[$mes]/$ano");
		push(@valores, $total);
	}
	
	# Monta o gráfico
	my $grafico = Chart::Bars->new(800, 600);
	my @dados = (\@grupos, \@valores);
	$grafico->set(
		'title' => 'Chamados por mes',
		'legend' => 'none',
		'include_zero' => 'true',
		'precision' => 0,
	);
	$grafico->cgi_png(\@dados);	
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
