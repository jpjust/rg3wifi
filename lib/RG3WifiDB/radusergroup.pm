package RG3WifiDB::radusergroup;

use base qw/DBIx::Class/;  

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('radusergroup');
# Set columns in table
__PACKAGE__->add_columns(qw/username groupname priority/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/username/);	# Xunxu pro delete() funcionar (não deletam sem chave primária)

1;
