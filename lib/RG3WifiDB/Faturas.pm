package RG3WifiDB::Faturas;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_faturas');
# Set columns in table
__PACKAGE__->add_columns(qw/id id_cliente id_usuario_resp id_situacao data_lancamento data_vencimento data_liquidacao descricao valor valor_pago banco_cob ag_cob/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'data_vencimento'});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(cliente				=> 'RG3WifiDB::Usuarios',			'id_cliente');
__PACKAGE__->belongs_to(situacao			=> 'RG3WifiDB::FaturasSituacao',	'id_situacao');
__PACKAGE__->belongs_to(banco_cobrador		=> 'RG3WifiDB::BancosLista',		'banco_cob');
__PACKAGE__->belongs_to(usuario_responsavel	=> 'RG3WifiDB::Usuarios',			'id_usuario_resp');

1;
