#!/usr/bin/perl -w

use Net::Ping::External qw(ping);
use FindBin;
use lib "$FindBin::Bin/../lib";
use RG3WifiDB;
use RG3Wifi::Model::RG3WifiDB;

# Configurações
my $output = '/usr/local/www/stats/aps';
my $count = '10';

# Horário
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$sec = '0' . $sec if ($sec < 10);
$min = '0' . $min if ($min < 10);
$hour = '0' . $hour if ($hour < 10);
$mon = '0' . $mon if ($mon < 10);
$mday = '0' . $mday if ($mday < 10);

# Arquivo de saída
my $filename = "$output/$year-$mon/$mday-$hour$min.html";

# Cor e status, de acordo com o resultado do PING
my @color = ('#ffaaaa', '#aaffaa');
my @status = ('Falhou', 'OK');

# Variáveis de contagem
my $num_total = 0;
my $num_alive = 0;

# Criar diretório de saída
mkdir "$output/$year-$mon";

# Conecta no banco de dados
my $schema = RG3WifiDB->connect(
	RG3Wifi::Model::RG3WifiDB->config->{connect_info}[0],
	RG3Wifi::Model::RG3WifiDB->config->{connect_info}[1],
	RG3Wifi::Model::RG3WifiDB->config->{connect_info}[2],
	RG3Wifi::Model::RG3WifiDB->config->{connect_info}[3]
);

# Abre arquivo de saída e escreve o cabeçalho HTML
open(HTML, ">$filename") or die;
flock(HTML, 2) or die;

print HTML <<CODE

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8" >
<title>Teste de rádios</title>
</head>

<body>
<p>Teste iniciado em $mday/$mon/$year às $hour:$min:$sec</p>

<table border="1">
	<tr>
		<th>IP</th>
		<th>Local</th>
		<th>Status</th>
	</tr>

CODE
;

# Testa cada rádio
foreach ($schema->resultset('Radios')->all) {
	next unless ($_->ip);
	
	my $alive = ping(host => $_->ip, count => $count);
	$num_total++;
	$num_alive += $alive;
	
	my $ip = $_->ip;
	my $local = $_->localizacao;
	
	print HTML <<CODE
	
	<tr bgcolor="$color[$alive]">
		<td><a href="http://$ip" target="_blank">$ip</td>
		<td>$local</td>
		<td>$status[$alive]</td>
	</tr>
CODE
;

}

# Escreve o resultado
my $pct = ($num_alive / $num_total) * 100;
print HTML <<CODE

</table>

<p>Hosts testados: $num_total</p>
<p>Hosts OK: $num_alive ($pct %)</p>

</body>
</html>

CODE
;

close(HTML);
