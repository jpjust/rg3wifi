package RG3WifiDB::Chamados;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_chamados');
# Set columns in table
__PACKAGE__->add_columns(qw/id id_tipo id_estado cliente endereco telefone motivo observacoes data_chamado data_conclusao/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'data_chamado'});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(tipo	=> 'RG3WifiDB::ChamadosTipo',	'id_tipo');
__PACKAGE__->belongs_to(estado	=> 'RG3WifiDB::ChamadosEstado',	'id_estado');

1;
