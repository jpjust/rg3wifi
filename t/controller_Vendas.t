use strict;
use warnings;
use Test::More;


use Catalyst::Test 'RG3Wifi';
use RG3Wifi::Controller::Vendas;

ok( request('/vendas')->is_success, 'Request should succeed' );
done_testing();
