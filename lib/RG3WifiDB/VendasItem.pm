package RG3WifiDB::VendasItem;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_vendas_item');
# Set columns in table
__PACKAGE__->add_columns(qw/id id_venda id_produto valor desconto/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'id_venda'});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(venda => 'RG3WifiDB::Vendas', 'id_venda');
__PACKAGE__->belongs_to(produto => 'RG3WifiDB::Produtos', 'id_produto');

1;
