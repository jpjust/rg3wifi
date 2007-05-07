package RG3WifiDB::radreply;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('radreply');
# Set columns in table
__PACKAGE__->add_columns(qw/id UserName Attribute op Value/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

1;
