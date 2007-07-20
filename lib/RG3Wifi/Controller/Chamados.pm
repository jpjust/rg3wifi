package RG3Wifi::Controller::Chamados;

use strict;
use warnings;
use base 'Catalyst::Controller';

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
	$c->stash->{suportes} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 1, id_estado => 1})];
	$c->stash->{estudos} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 2, id_estado => 1})];
	$c->stash->{instalacoes} = [$c->model('RG3WifiDB::Chamados')->search({id_tipo => 3, id_estado => 1})];
	$c->stash->{template} = 'chamados/lista.tt2';
}

=head2 novo

Exibe formulário de abertura de chamado.

=cut

sub novo : Local {
	my ($self, $c) = @_;
	$c->stash->{tipos} = [$c->model('RG3WifiDB::ChamadosTipo')->all];
	$c->stash->{acao} = 'novo';
	$c->stash->{template} = 'chamados/novo.tt2';
}


=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
