
# GUSdev
#
./grantPermissions.pl --login=gusdev --permissions=select --grantees=PUBLIC --owner=gusdev --verbose
./grantPermissions.pl --login=gusdev --permissions=insert,update,delete --grantees=GUSrw --owner=gusdev --verbose

./createSynonyms.pl --login=sys --owner=gusdev --targets=GUSrw,gusdevreadonly,guswww --verbose

# RADdev
#
./grantPermissions.pl --login=raddev --permissions=select --grantees=RAD_READ_ROLE --owner=raddev --verbose

./createSynonyms.pl --login=sys --owner=raddev --targets=raddevreadonly,radwww --verbose

