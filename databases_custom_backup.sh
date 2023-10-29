#!/bin/bash

## Custom Database backup script
## Requires credentials in ~/.my.cnf
## George Dimitrakopoulos 2023

## some vars
E_NOTROOT=87 # non root exit error code
E_NOTFOUND=2 # file not found exit error code
SUFFIX=$(date +%Y%m%d) # edit this for another suffix
DEST="/backup/custom_db/" # edit this for different output folder. Always add a slash at the end
MYCNF="/root/.my.cnf" # location of .my.cnf file

## Prevent script execution without root privileges
if [ "${UID:-$(id -u)}" -ne "0" ]; then
    if ! $(sudo -l &>/dev/null); then
        echo 'Please run this script as root or with root privileges'
        exit $E_NOTROOT
    fi
fi

## check that my.cnf is present
if [ ! -f "$MYCNF" ];then
    echo 'No my.cnf file found! Please provide one at ~ ! Exiting...'
    exit $E_NOTFOUND
else
    case `grep -Fw "root" "$MYCNF" >/dev/null; echo $?` in
      0)
      echo 'Mysql/MariaDB root user credentials found in .my.cnf. This is discouraged.'
      ;;
      1)
      # good, do nothing
      ;;
      *)
      # uknown error occured, cannot test for root in my.cnf
      ;;
    esac
fi

## exclude system dbs
ExcludeDbs="Database|information_schema|performance_schema|mysql"

# get a list of databases
databases=`mysql --defaults-extra-file=/root/.my.cnf --batch --skip-column-names  -Bse "SHOW DATABASES;" | egrep -v $ExcludeDbs`


## check if output dir exists and if not make it
if [ ! -d "$DEST" ];then
    sudo mkdir -p "$DEST"
fi


## loop through list and backup, then nice gzip
for db in $databases; do
    echo "Dumping database: ${DEST}${db}-${SUFFIX}.sql"
    nice -n 5 mysqldump --defaults-extra-file=/root/.my.cnf  --lock-tables --databases $db > ${DEST}${db}-${SUFFIX}.sql && sync && nice gzip ${DEST}${db}-${SUFFIX}.sql && rm -y ${DEST}${db}-${SUFFIX}.sql
done

## thats it!
