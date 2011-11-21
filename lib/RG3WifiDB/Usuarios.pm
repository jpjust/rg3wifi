package RG3WifiDB::Usuarios;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_usuarios');
# Set columns in table
__PACKAGE__->add_columns(qw/uid id_grupo id_situacao id_banco data_adesao bloqueado nao_bloqueia inadimplente nome doc data_nascimento telefone endereco bairro cidade id_estado cep observacao email kit_proprio cabo valor_instalacao valor_mensalidade valor_mensalidade_prox vencimento/);
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
__PACKAGE__->belongs_to(estado => 'RG3WifiDB::Estados', 'id_estado');
__PACKAGE__->belongs_to(banco => 'RG3WifiDB::Bancos', 'id_banco');

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(contas => 'RG3WifiDB::Contas', 'id_cliente');
__PACKAGE__->has_many(faturas => 'RG3WifiDB::Faturas', 'id_cliente');
__PACKAGE__->has_many(faturas_baixadas => 'RG3WifiDB::Faturas', 'id_usuario_resp');

1;
