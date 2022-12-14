package RG3Wifi::Controller::Login;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

RG3Wifi::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
	my ($self, $c) = @_;
	
	if ($c->user_exists) {
		$c->response->redirect($c->uri_for('/acesso/inicio'));
	}

	my $username = $c->request->params->{username} || "";
	my $password = $c->request->params->{password} || "";
	
	if ($username && $password) {
		if ($c->login($username, $password)) {
			$c->response->redirect($c->uri_for('/acesso/inicio'));
		} else {
			$c->stash->{error_msg} = "Usuário e/ou senha inválidos.";
		}
	}
	
	$c->stash->{template} = 'login.tt2';
}


=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
