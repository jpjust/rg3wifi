package RG3WifiDB::BancosLista;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_bancos_lista');
# Set columns in table
__PACKAGE__->add_columns(qw/numero nome/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/numero/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'nome'});

1;
