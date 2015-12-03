#!/bin/bash

# "Others" should not have any access to new files or dirs
umask 0027

NOW=`date +"%Y-%m-%d"`;
BACKUPBASEDIR="/l/mysql_backups"
BACKUPDATADIR="${BACKUPBASEDIR}/data"
BACKUPAUTHDIR="${BACKUPBASEDIR}/auth"
BACKUPDIR="${BACKUPDATADIR}/${NOW}"
DEFAULTSFILE="/tmp/.my_defaults_$$"

### Server Setup ###
MUSER="mybackup";

# Obtain password from binary
MPASS=$(${BACKUPAUTHDIR}/${MUSER}.out);

#* MySQL login HOST name *#
MHOST="localhost";
MPORT="3306";

# DO NOT BACKUP these databases
IGNOREDB="
performance_schema
"

#* MySQL binaries *#
MYSQL="/usr/local/mysql/bin/mysql"
MYSQLDUMP="/usr/local/mysql/bin/mysqldump"
GZIP="/bin/gzip"

cat > $DEFAULTSFILE <<ENDDEFAULTS
[client]
password=$MPASS
ENDDEFAULTS

if [ ! -d $BACKUPDIR ]; then
  mkdir -p $BACKUPDIR
else
 :
fi

# get all database listing
DBS="$($MYSQL --defaults-file=$DEFAULTSFILE -u $MUSER -h $MHOST -P $MPORT -Bse 'show databases')"

for db in $DBS; do
   DUMP="yes";
   if [ "$IGNOREDB" != "" ]; then
      for i in $IGNOREDB; do
         if [ "$db" == "$i" ]; then
             DUMP="NO";
         fi
      done
   fi

   if [ "$DUMP" == "yes" ]; then
      FILE="$BACKUPDIR/$db.gz";
      $MYSQLDUMP --defaults-file=$DEFAULTSFILE --add-drop-database \
         --opt --lock-all-tables \
         -u $MUSER -h $MHOST -P $MPORT $db | gzip > $FILE
   fi
done

find ${BACKUPDATADIR} -type d -mtime +8 -exec /bin/rm -rf {} \;

/bin/rm -f $DEFAULTSFILE
