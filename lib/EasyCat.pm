package EasyCat;

our $VERSION = '0.2';

=head2 data2normal

Converte data de formato SQL para normal

=cut

sub data2normal {
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

sub data2sql {
	my ($dia, $mes, $ano, $hora, $minuto) = split(/[^0-9]/, $_[0]);
	$ano = 1900 + abs($ano) if ($ano < 100);
	$mes = '0' . abs($mes) if ($mes < 10);
	$dia = '0' . abs($dia) if ($dia < 10);

	if ($ano && $mes && $dia && $hora && $minuto) {
		return "$ano-$mes-$dia $hora:$minuto:00";
	} elsif ($ano && $mes && $dia) {
		return "$ano-$mes-$dia";
	} else {
		return undef;
	}
}

=head2 datacmp

Compara duas datas, ignorando a parte de hora

=cut

sub datacmp {
	my ($d1, $lixo1) = split(/ /, $_[0]);
	my ($d2, $lixo2) = split(/ /, $_[1]);
	
	if (&data2sql($d1) eq &data2sql($d2)) {
		return 1;
	} else {
		return 0;
	}
}

=head2 formatadoc

Retorna o número do documento (CPF/CNPJ) formatado com pontos e hífen.

=cut

sub formatadoc {
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

1;
