package RG3WifiDB::Produtos;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_produtos');
# Set columns in table
__PACKAGE__->add_columns(qw/id id_unidade id_fornecedor codigo descricao custo valor estoque/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'descricao'});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(fornecedor => 'RG3WifiDB::Fornecedores', 'id_fornecedor');
__PACKAGE__->belongs_to(unidade => 'RG3WifiDB::Unidades', 'id_unidade');

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(venda_item => 'RG3WifiDB::VendaItem', 'id_produto');

1;
