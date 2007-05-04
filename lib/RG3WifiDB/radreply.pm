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

#
# Set relationships:
#

# might_have():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->might_have(cliente => 'RG3WifiDB::Usuarios', 'id_radreply');

1;
