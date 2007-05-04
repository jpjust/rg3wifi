package RG3WifiDB::Usuarios;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_usuarios');
# Set columns in table
__PACKAGE__->add_columns(qw/uid id_grupo id_radcheck id_radreply login senha nome/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/uid/);

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(grupo => 'RG3WifiDB::Grupos', 'id_grupo');
__PACKAGE__->belongs_to(radcheck => 'RG3WifiDB::radcheck', 'id_radcheck');
__PACKAGE__->belongs_to(radreply => 'RG3WifiDB::radreply', 'id_radreply');

1;
