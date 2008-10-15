package RG3WifiDB::Contas;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_contas');
# Set columns in table
__PACKAGE__->add_columns(qw/uid id_cliente id_grupo id_plano login senha ip/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/uid/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'login'});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(cliente => 'RG3WifiDB::Usuarios', 'id_cliente');
__PACKAGE__->belongs_to(plano => 'RG3WifiDB::Planos', 'id_plano');
__PACKAGE__->belongs_to(grupo => 'RG3WifiDB::Grupos', 'id_grupo');

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(acoes => 'RG3WifiDB::Auditoria', 'uid');

1;
