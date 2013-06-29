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

##### UNIDADES #####

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

=head2 editar_produto_unidade

Exibe a tela para editar tipo de unidade.

=cut

sub editar_produto_unidade : Local {
    my ($self, $c, $id) = @_;
    my $unidade = $c->model('RG3WifiDB::Unidades')->search({id => $id})->first;
    if (!$unidade) {
    	$c->stash->{error_msg} = 'Unidade de produto não localizada!';
    	$c->forward('lista_produto_unidade');
    } else {
    	$c->stash->{unidade} = $unidade;
		$c->forward('novo_produto_unidade');
    }
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

##### FORNECEDORES #####

=head2 lista_fornecedor

Lista os fornecedores.

=cut

sub lista_fornecedor : Local {
    my ($self, $c) = @_;
    
	$c->stash->{fornecedores} = [$c->model('RG3WifiDB::Fornecedores')->all];
	$c->stash->{template} = 'vendas/lista_fornecedor.tt2';
}

=head2 novo_fornecedor

Exibe a tela para cadastro de novo fornecedor.

=cut

sub novo_fornecedor : Local {
    my ($self, $c) = @_;
    $c->stash->{estados} = [$c->model('RG3WifiDB::Estados')->all];
	$c->stash->{template} = 'vendas/novo_fornecedor.tt2';
}

=head2 editar_fornecedor

Exibe a tela para editar um fornecedor.

=cut

sub editar_fornecedor : Local {
    my ($self, $c, $id) = @_;
    my $fornecedor = $c->model('RG3WifiDB::Fornecedores')->search({id => $id})->first;
    if (!$fornecedor) {
    	$c->stash->{error_msg} = 'Fornecedor não localizado!';
    	$c->forward('lista_fornecedor');
    } else {
    	$c->stash->{fornecedor} = $fornecedor;
		$c->forward('novo_fornecedor');
    }
}

=head2 novo_fornecedor_do

Efetua a inclusão de um novo fornecedor.

=cut

sub novo_fornecedor_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id			=> $p->{id}			|| -1,
		nome		=> $p->{nome}		|| undef,
		contato		=> $p->{contato}	|| undef,
		cnpj		=> $p->{cnpj}		|| undef,
		endereco	=> $p->{endereco}	|| undef,
		bairro		=> $p->{bairro}		|| undef,
		cidade		=> $p->{cidade}		|| undef,
		id_estado	=> $p->{id_estado}	|| undef,
		cep			=> $p->{cep}		|| undef,
		telefone	=> $p->{telefone}	|| undef,
		email		=> $p->{email}		|| undef,
	});
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(nome contato cnpj endereco bairro cidade id_estado cep telefone)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{fornecedor} = $dados;
		$c->forward('novo_fornecedor');
		return;
	}

	# Atualiza o banco
	eval {
		$c->model('RG3WifiDB::Fornecedores')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao incluir/editar fornecedor: ' . $@;
		$c->stash->{template} = 'error.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Fornecedor incluído com sucesso.';
	$c->forward('lista_fornecedor');
}

=head2 excluir_fornecedor

Exclui um fornecedor.

=cut

sub excluir_fornecedor : Local {
	my ($self, $c, $id) = @_;
	my $fornecedor = $c->model('RG3WifiDB::Fornecedores')->search({id => $id})->first;
	$fornecedor->delete();
	$c->stash->{status_msg} = 'Fornecedor excluído com sucesso.';
	$c->forward('lista_fornecedor');
}

##### PRODUTOS #####

=head2 lista_produto

Lista os produtos.

=cut

sub lista_produto : Local {
    my ($self, $c) = @_;
	$c->stash->{produtos} = [$c->model('RG3WifiDB::Produtos')->all];
	$c->stash->{template} = 'vendas/lista_produto.tt2';
}

=head2 novo_produto

Exibe a tela para cadastro de novo produto.

=cut

sub novo_produto : Local {
    my ($self, $c) = @_;
    $c->stash->{fornecedores} = [$c->model('RG3WifiDB::Fornecedores')->all];
    $c->stash->{unidades} = [$c->model('RG3WifiDB::Unidades')->all];
	$c->stash->{template} = 'vendas/novo_produto.tt2';
}

=head2 editar_produto

Exibe a tela para editar um produto.

=cut

sub editar_produto : Local {
    my ($self, $c, $id) = @_;
    my $produto = $c->model('RG3WifiDB::Produtos')->search({id => $id})->first;
    if (!$produto) {
    	$c->stash->{error_msg} = 'Produto não localizado!';
    	$c->forward('lista_produto');
    } else {
    	$c->stash->{produto} = $produto;
		$c->forward('novo_produto');
    }
}

=head2 novo_produto_do

Efetua a inclusão de um novo produto.

=cut

sub novo_produto_do : Local {
	my ($self, $c) = @_;
	
	# Parâmetros
	my $p = $c->request->params;
	
	# Efetua o cadastro
	my $dados = ({
		id				=> $p->{id}				|| -1,
		codigo			=> $p->{codigo}			|| undef,
		id_fornecedor	=> $p->{id_fornecedor}	|| undef,
		descricao		=> $p->{descricao}		|| undef,
		custo			=> $p->{custo}			|| undef,
		valor			=> $p->{valor}			|| undef,
		estoque			=> $p->{estoque}		|| undef,
		id_unidade		=> $p->{id_unidade}		|| undef,
	});
	
	# Valida formulário
	my $val = Data::FormValidator->check(
		$dados,
		{required => [qw(codigo id_fornecedor descricao custo valor estoque)]}
	);
	
	if (!$val->success()) {
		$c->stash->{val} = $val;
		$c->stash->{produto} = $dados;
		$c->forward('novo_produto');
		return;
	}

	# Atualiza o banco
	eval {
		$c->model('RG3WifiDB::Produtos')->update_or_create($dados);
	};
	
	if ($@) {
		$c->stash->{error_msg} = 'Erro ao incluir/editar produto: ' . $@;
		$c->stash->{template} = 'error.tt2';
		return;
	}
	
	# Exibe mensagem de conclusão
	$c->stash->{status_msg} = 'Produto incluído com sucesso.';
	$c->forward('lista_produto');
}

=head2 excluir_produto

Exclui um produto.

=cut

sub excluir_produto : Local {
	my ($self, $c, $id) = @_;
	my $produto = $c->model('RG3WifiDB::Produtos')->search({id => $id})->first;
	$produto->delete();
	$c->stash->{status_msg} = 'Produto excluído com sucesso.';
	$c->forward('lista_produto');
}

=head1 AUTHOR

Joao Paulo Just Peixoto,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
