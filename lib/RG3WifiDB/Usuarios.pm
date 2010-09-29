package RG3WifiDB::Usuarios;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_usuarios');
# Set columns in table
__PACKAGE__->add_columns(qw/uid id_grupo id_situacao data_adesao bloqueado nao_bloqueia inadimplente nome doc data_nascimento telefone endereco bairro cep observacao kit_proprio cabo valor_instalacao valor_mensalidade vencimento/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/uid/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'nome', rows => 10});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(grupo => 'RG3WifiDB::Grupos', 'id_grupo');
__PACKAGE__->belongs_to(situacao => 'RG3WifiDB::UsuariosSituacao', 'id_situacao');

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(contas => 'RG3WifiDB::Contas', 'id_cliente');
__PACKAGE__->has_many(faturas => 'RG3WifiDB::Faturas', 'id_cliente');

1;
