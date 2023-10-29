#!/bin/bash

# Custom Database backup script
# Requires credentials in ~/.my.cnf
# George Dimitrakopoulos 2023

# some vars
E_NOTROOT=87 # Non-root exit error.
SUFFIX=$(date +%Y%m%d)
DEST="/backup/custom_db/" #always add a slash at the end

# exclude system dbs
ExcludeDbs="Database|information_schema|performance_schema|mysql"
# get a list of databases
databases=`mysql --defaults-extra-file=/root/.my.cnf --batch --skip-column-names  -Bse "SHOW DATABASES;" | egrep -v $ExcludeDbs`


# check if output dir exists and if not make it
if [ ! -d "$DEST" ];then
  sudo mkdir -p "$DEST"
fi


#loop through list and backup, then nice gzip
for db in $databases; do
    echo "Dumping database: ${DEST}${db}-${SUFFIX}.sql"
    nice -n 5 mysqldump --defaults-extra-file=/root/.my.cnf  --lock-tables --databases $db > ${DEST}${db}-${SUFFIX}.sql && sync && nice gzip ${DEST}${db}-${SUFFIX}.sql && rm -y ${DEST}${db}-${SUFFIX}.sql
done

#thats it!
