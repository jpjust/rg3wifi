use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'RG3Wifi' }
BEGIN { use_ok 'RG3Wifi::Controller::Caixa' }

ok( request('/caixa')->is_success, 'Request should succeed' );


