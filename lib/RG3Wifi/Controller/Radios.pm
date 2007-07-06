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
	$c->stash->{radios} = [$c->model('RG3WifiDB::Radios')->all];
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

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
