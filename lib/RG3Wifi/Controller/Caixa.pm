package RG3Wifi::Controller::Caixa;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use FindBin;
use lib "$FindBin::Bin/../..";
use EasyCat;
use Data::FormValidator;
use DateTime;
use Chart::Lines;

=head1 NAME

RG3Wifi::Controller::Caixa - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index :Path :Args(0) {
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

=head2 gera_lista

Gera a lista de movimentações de acordo com as datas.

=cut

sub gera_lista : Local {
	my ($self, $c, $data1, $data2, $id_banco) = @_;
	
	$c->stash->{lancamentos} = [$c->model('RG3WifiDB::Caixa')->search({data => {
			-between => [&EasyCat::data2sql($data1), &EasyCat::data2sql($data2)]
		}, id_banco => $id_banco})];
	
	# Calcula o total de cada categoria
	my @categorias;
	foreach my $categoria ($c->model('RG3WifiDB::CaixaCategoria')->all) {
		my $rs = $c->model('RG3WifiDB::Caixa')->search(
		{
			data			=> {-between => [&EasyCat::data2sql($data1), &EasyCat::data2sql($data2)]},
			id_categoria	=> $categoria->id,
			id_banco		=> $id_banco,
		}, {
			select	=> [{sum => 'valor'}],
			as		=> ['valor_total'],
		});
		
		my $dados = ({
			nome	=> $categoria->nome,
			valor	=> $rs->first->get_column('valor_total') || 0,
		});
		push(@categorias, $dados);
	}
	
	# Se a listagem for pro caixa da loja, atualiza o saldo do dia
	&atualiza_saldo($self, $c, $data1);

	$c->stash->{data1} = $data1;
	$c->stash->{data2} = $data2;
	$c->stash->{banco} = $c->model('RG3WifiDB::Bancos')->find($id_banco);
	$c->stash->{bancos} = [$c->model('RG3WifiDB::Bancos')->all];
	$c->stash->{categorias} = [@categorias];
	$c->stash->{template} = 'caixa/lista.tt2';
}

=head2 lista

Lista as movimentações no banco.

=cut

sub lista : Local {
    my ($self, $c, $banco) = @_;
    
    # Se o banco não for especificado, usa o caixa da loja
    unless ($banco) {
    	&lista_loja($self, $c);
    	return;
    }
    
	# Lista apenas a última semana e a semana seguinte
	my $data1 = DateTime->now();
	my $data2 = DateTime->now();
	
	$data1->subtract(days => 7);
	$data2->add(days => 7);
	
	$data1 = $data1->dmy('/');
	$data2 = $data2->dmy('/');
	
	&gera_lista($self, $c, $data1, $data2, $banco);
}

=head2 lista_loja

Lista as movimentações na loja.

=cut

sub lista_loja : Local {
    my ($self, $c, $data) = @_;
    my ($data1, $data2);
    
	# Se $data estiver definido, use. Senão, use a data atual.
	if ($data) {
		$data1 = $data;
		$data2 = $data;
	} else {
		$data1 = DateTime->now()->dmy('/');
		$data2 = DateTime->now()->dmy('/');
	}
	
	&gera_lista($self, $c, $data1, $data2, 0);
}

=head2 filtro

Lista os lançamentos de acordo com o filtro configurado.

=cut

sub filtro : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	$p->{data2} = $p->{data1} if ($p->{data2} == undef || $p->{banco} == 0);
	
	&gera_lista($self, $c, $p->{data1}, $p->{data2}, $p->{banco});
}

=head2 novo

Abre página de inclusão de lançamento.

=cut

sub novo : Local {
	my ($self, $c) = @_;
	$c->stash->{categorias} = [$c->model('RG3WifiDB::CaixaCategoria')->all];
	$c->stash->{formas} = [$c->model('RG3WifiDB::CaixaForma')->all];
	$c->stash->{acao} = 'novo';
	$c->stash->{bancos} = [$c->model('RG3WifiDB::Bancos')->all];
	$c->stash->{template} = 'caixa/novo.tt2';
}

=head2 editar

Exibe formulário para editar lançamento.

=cut

sub editar : Local {
	my ($self, $c, $id) = @_;
	$c->stash->{lancamento} = $c->model('RG3WifiDB::Caixa')->search({id => $id})->first;
	$c->stash->{acao} = 'editar';
	$c->forward('novo');
}

=head2 novo_do

Efetua a inclusão de um novo lançamento.

=cut

sub novo_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id					=> $p->{id}					|| -1,
		id_categoria		=> $p->{categoria}			|| undef,
		id_forma			=> $p->{forma}				|| undef,
		id_banco			=> $p->{banco}				|| 0,
		data				=> &EasyCat::data2sql($p->{data})	|| undef,
		valor				=> $p->{valor}				|| undef,
		credito				=> $p->{credito}			|| 0,
		lancamento_futuro	=> $p->{lancamento_futuro}	|| 0,
		descricao			=> $p->{descricao}			|| undef,
		favorecido			=> $p->{favorecido}			|| undef,
	});
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(id_categoria id_forma data valor descricao favorecido)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{lancamento} = $dados;
		$c->forward('novo');
		return;
	}

	# Atualiza o banco
	eval {
		$c->model('RG3WifiDB::Caixa')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao incluir/editar lançamento: ' . $@;
		$c->stash->{template} = 'erro.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Lançamento incluído com sucesso.';
	$c->forward('lista');
}

=head2 excluir

Exclui um lançamento.

=cut

sub excluir : Local {
	my ($self, $c, $id) = @_;
	$c->model('RG3WifiDB::Caixa')->search({id => $id})->delete_all();
	$c->stash->{status_msg} = 'Lançamento excluído!';
	$c->forward('lista');
}

=head2 chart_movimentacao

Gera um gráfico de entrada e saída totais em cada mês.

=cut

sub chart_movimentacao : Local {
	my ($self, $c) = @_;
	
	# Pesquisa no BD quanto entrou e saiu em cada mês
	my @grupos = ();
	my @valores_entrada = ();
	my @valores_saida = ();
	my @hora = localtime(time);
	my $mes_atual = $hora[4];
	my $ano_atual = $hora[5] + 1900;
	my @meses = qw( Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez );
	
	for (my $i = 12; $i > 0; $i--) {
		my $mes = ($mes_atual - $i) % 12;
		my $ano = ($mes_atual - $i) >= 0 ? $ano_atual : $ano_atual - 1;
		my $data1 = $ano . '-' . abs($mes + 1) . '-01';
		my $data2 = $ano . '-' . abs($mes + 1) . '-31';
		my $entrada = $c->model('RG3WifiDB::Caixa')->search({credito => 1, data => {-between => [$data1, $data2]}}, {select => [{sum => 'valor'}], as => ['total']});
		my $saida = $c->model('RG3WifiDB::Caixa')->search({credito => 0, data => {-between => [$data1, $data2]}}, {select => [{sum => 'valor'}], as => ['total']});
		push(@grupos, "$meses[$mes]/$ano");
		push(@valores_entrada, $entrada->first->get_column('total'));
		push(@valores_saida, $saida->first->get_column('total'));
	}
	
	# Monta o gráfico
	my $grafico = Chart::Lines->new(800, 600);
	my @dados = (\@grupos, \@valores_saida, \@valores_entrada);
	my @legendas = ('Saida', 'Entrada');
	$grafico->set(
		'title' => 'Entrada e saida por mes',
		'include_zero' => 'true',
		'legend_labels' => \@legendas,
		'precision' => 2,
	);
	$grafico->cgi_png(\@dados);	
}

=head2 atualiza_saldo

Atualiza o saldo do dia para o caixa da loja.

=cut

sub atualiza_saldo : Private {
	my ($self, $c, $data) = @_;
	
	# Calcula a movimentação do dia
	my $saldo_dia = 0;
	foreach my $movimento ($c->model('RG3WifiDB::Caixa')->search({id_banco => 0, data => &EasyCat::data2sql($data)})) {
		if ($movimento->credito) {
			$saldo_dia += $movimento->valor;
		} else {
			$saldo_dia -= $movimento->valor;
		}
	}
	
	# Atualiza o saldo atual
	my $dados = ({
		data => &EasyCat::data2sql($data),
		saldo => $saldo_dia,
	});
	$c->model('RG3WifiDB::CaixaLoja')->update_or_create($dados);
}

=head1 AUTHOR

Joao Paulo Just Peixoto,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
