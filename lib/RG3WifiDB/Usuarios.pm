package RG3WifiDB::Usuarios;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_usuarios');
# Set columns in table
__PACKAGE__->add_columns(qw/uid data_adesao bloqueado nome rg doc data_nascimento telefone endereco bairro cep observacao kit_proprio cabo valor_instalacao valor_mensalidade/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/uid/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'nome'});

#
# Set relationships:
#

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(contas => 'RG3WifiDB::Contas', 'id_cliente');

1;
