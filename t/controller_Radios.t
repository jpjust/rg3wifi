use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'RG3Wifi' }
BEGIN { use_ok 'RG3Wifi::Controller::Radios' }

ok( request('/radios')->is_success, 'Request should succeed' );


