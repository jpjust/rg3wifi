package RG3Wifi::Controller::Logout;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

RG3Wifi::Controller::Logout - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
	my ($self, $c) = @_;
	$c->logout;
	$c->response->redirect($c->uri_for('/'));
}


=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
