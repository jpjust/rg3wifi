package RG3WifiDB::radacct;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('radacct');
# Set columns in table
__PACKAGE__->add_columns(qw/RadAcctId AcctSessionId AcctUniqueId UserName Realm NASIPAddress NASPortId NASPortType AcctStartTime AcctStopTime AcctSessionTime AcctAuthentic ConnectInfo_start ConnectInfo_stop AcctInputOctets AcctOutputOctets CalledStationId CallingStationId AcctTerminateCause ServiceType FramedProtocol FramedIPAddress AcctStartDelay AcctStopDelay/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/RadAcctId/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'AcctStartTime DESC', rows => 100});

1;
