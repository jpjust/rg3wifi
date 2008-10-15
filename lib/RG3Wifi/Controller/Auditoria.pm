package RG3Wifi::Controller::Auditoria;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

RG3Wifi::Controller::Auditoria - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
	my ($self, $c) = @_;
}

=head2 logs

Mostra log de auditoria.

=cut

sub logs : Local {
	use integer;
	my ($self, $c, $pagina) = @_;
	
	$pagina = 1 unless($pagina);
	
	# Exibe o log
	my $acoes = $c->model('RG3WifiDB::Auditoria')->page($pagina);
	$c->stash->{acoes} = [$acoes->all];
	$c->stash->{paginas} = $acoes->pager->last_page;
	$c->stash->{pagina} = $pagina;
	$c->stash->{template} = 'auditoria/logs.tt2';
}

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
