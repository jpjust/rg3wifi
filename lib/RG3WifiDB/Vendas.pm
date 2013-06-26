package RG3WifiDB::Vendas;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_vendas');
# Set columns in table
__PACKAGE__->add_columns(qw/id id_vendedor data cliente/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'data'});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(vendedor => 'RG3WifiDB::Usuarios', 'id_vendedor');

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(venda_item => 'RG3WifiDB::VendasItem', 'id_venda');

1;
