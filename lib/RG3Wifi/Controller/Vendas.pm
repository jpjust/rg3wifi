package RG3Wifi::Controller::Vendas;

use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../..";
use EasyCat;
use Data::FormValidator;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

RG3Wifi::Controller::Vendas - Catalyst Controller

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

=head2 lista

Lista as vendas.

=cut

sub lista : Local {
    my ($self, $c) = @_;
    
	$c->stash->{vendas} = [$c->model('RG3WifiDB::Vendas')->all];
	$c->stash->{template} = 'vendas/lista.tt2';
}

=head2 lista_produto_unidade

Lista os tipos de unidades.

=cut

sub lista_produto_unidade : Local {
    my ($self, $c) = @_;
    
	$c->stash->{unidades} = [$c->model('RG3WifiDB::Unidades')->all];
	$c->stash->{template} = 'vendas/lista_produto_unidade.tt2';
}

=head2 novo_produto_unidade

Exibe a tela para cadastro de novo tipo de unidade.

=cut

sub novo_produto_unidade : Local {
    my ($self, $c) = @_;
	$c->stash->{template} = 'vendas/novo_produto_unidade.tt2';
}

=head2 novo_produto_unidade_do

Efetua a inclusão de uma nova unidade de produto.

=cut

sub novo_produto_unidade_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id		=> $p->{id}		|| -1,
		nome	=> $p->{nome}	|| undef,
	});
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(nome)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{unidade} = $dados;
		$c->forward('novo_produto_unidade');
		return;
	}

	# Atualiza o banco
	eval {
		$c->model('RG3WifiDB::Unidades')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao incluir/editar unidade: ' . $@;
		$c->stash->{template} = 'error.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Unidade incluída com sucesso.';
	$c->forward('lista_produto_unidade');
}

=head2 excluir_produto_unidade

Exclui um tipo de unidade.

=cut

sub excluir_produto_unidade : Local {
	my ($self, $c, $id) = @_;
	my $unidade = $c->model('RG3WifiDB::Unidades')->search({id => $id})->first;
	$unidade->delete();
	$c->stash->{status_msg} = 'Unidade excluída com sucesso.';
	$c->forward('lista_produto_unidade');
}


=head1 AUTHOR

Joao Paulo Just Peixoto,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
