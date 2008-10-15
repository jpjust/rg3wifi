package RG3WifiDB::Auditoria;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('rg3_auditoria');
# Set columns in table
__PACKAGE__->add_columns(qw/uid acao data/);

# Add some attributes
__PACKAGE__->resultset_attributes({order_by => 'data DESC', rows => 100});

#
# Set relationships:
#

# belongs_to():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of the model class referenced by this relationship
#     3) Column name in *this* table
__PACKAGE__->belongs_to(login => 'RG3WifiDB::Contas', 'uid');

1;
