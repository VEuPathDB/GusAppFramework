
# Run online backup weekly
#
./onlineBackup.pl --login=sys --tarFile=/dev/nst0 --logDir=/usr/local/oracle/backup --dataFilesOnly --gzip

# Essential TABLESPACES only (INDX borderline)
#
./onlineBackup.pl --login=sys --tarFile=/dev/nst0 --logDir=/usr/local/oracle/backup --dataFilesOnly --tablespaces=SYSTEM,TOOLS,USERS

# Backup archived redo logs daily
#
./onlineBackup.pl --login=sys --tarFile=/dev/nst0 --logDir=/usr/local/oracle/backup --archivedLogsOnly --forceSwitch --gzip
