package RG3Wifi;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst qw/
	-Debug
	StackTrace

	ConfigLoader
	Static::Simple
	
	Authentication
	Authentication::Store::DBIC
	Authentication::Credential::Password
	Authorization::Roles
	Authorization::ACL
	
	Session
	Session::Store::FastMmap
	Session::State::Cookie
	/;

our $VERSION = '0.02';

# Configure the application. 
#
# Note that settings in RG3Wifi.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'RG3Wifi' );

# Start the application
__PACKAGE__->setup;

# Authorization::ACL Rules
# Cadastro (geral)
__PACKAGE__->allow_access_if("/cadastro", [qw/admin/]);
__PACKAGE__->allow_access_if("/cadastro", [qw/operador/]);
__PACKAGE__->deny_access("/cadastro");

# Cadastro (exclusão)
__PACKAGE__->allow_access_if("/cadastro/excluir", [qw/admin/]);
__PACKAGE__->deny_access("/cadastro/excluir");

# Rádios (geral)
__PACKAGE__->allow_access_if("/radios", [qw/admin/]);
__PACKAGE__->allow_access_if("/radios", [qw/operador/]);
__PACKAGE__->deny_access("/radios");


=head2 data2normal

Converte data de formato SQL para normal

=cut

sub data2normal : Public {
	if (length($_[0]) == 10) {
		my ($ano, $mes, $dia) = split('-', $_[0]);
		return "$dia/$mes/$ano";
	} elsif (length($_[0]) > 10) {
		my ($ano, $mes, $dia, $hora, $minuto) = split(/[^0-9]/, $_[0]);
		return "$dia/$mes/$ano $hora:$minuto";
	} else {
		return undef;
	}
}

=head2 data2sql

Converte data de formato normal para SQL

=cut

sub data2sql : Public {
	if (length($_[0]) == 10) {
		my ($dia, $mes, $ano) = split('/', $_[0]);
		return "$ano-$mes-$dia";
	} elsif (length($_[0]) > 10) {
		my ($dia, $mes, $ano, $hora, $minuto) = split(/[^0-9]/, $_[0]);
		$mes = '0' . $mes if ($mes < 10);
		$dia = '0' . $dia if ($dia < 10);
		return "$ano-$mes-$dia $hora:$minuto:00";
	} else {
		return undef;
	}
}

=head2 formatadoc

Retorna o número do documento (CPF/CNPJ) formatado com pontos e hífen.

=cut

sub formatadoc : Public {
	my ($doc) = @_;
	
	# Formata CPF
	if (length($doc) == 11) {
		my $a = substr($doc, 0, 3);
		my $b = substr($doc, 3, 3);
		my $c = substr($doc, 6, 3);
		my $d = substr($doc, 9, 2);
		return "$a.$b.$c-$d";
	}
	# Formata CNPJ
	elsif (length($doc) == 14) {
		my $a = substr($doc, 0, 2);
		my $b = substr($doc, 2, 3);
		my $c = substr($doc, 5, 3);
		my $d = substr($doc, 8, 4);
		my $e = substr($doc, 12, 2);
		return "$a.$b.$c/$d-$e";
	}
	# Número de tamanho inválido
	else {
		return $doc;
	}
}

=head1 NAME

RG3Wifi - Catalyst based application

=head1 SYNOPSIS

    script/rg3wifi_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<RG3Wifi::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Joao Paulo Just,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
