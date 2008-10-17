package RG3WifiDB::Radios;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_radios');
# Set columns in table
__PACKAGE__->add_columns(qw/id id_modelo id_base id_tipo mac data_instalacao localizacao id_banda ip essid/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(base		=> 'RG3WifiDB::Radios', 'id_base');
__PACKAGE__->belongs_to(modelo		=> 'RG3WifiDB::Modelos', 'id_modelo');
__PACKAGE__->belongs_to(tipo		=> 'RG3WifiDB::RadiosTipo', 'id_tipo');
__PACKAGE__->belongs_to(banda		=> 'RG3WifiDB::RadiosBanda', 'id_banda');

# has_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *foreign* table
__PACKAGE__->has_many(estacoes => 'RG3WifiDB::Radios', 'id_base');

1;
