package RG3WifiDB::CaixaLoja;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_caixa_loja');
# Set columns in table
__PACKAGE__->add_columns(qw/id data saldo_inicial cedulas_i moedas_i cheques_i saldo_final cedulas_f moedas_f cheques_f/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);
# Add unique constraint
__PACKAGE__->add_unique_constraint([qw/data/]);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'data'});

1;
