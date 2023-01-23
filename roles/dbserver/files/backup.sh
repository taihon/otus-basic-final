#!/bin/bash

MYSQL="mysql --skip-column-names ";
MYSQLDMP="/usr/bin/mysqldump"
for db in `$MYSQL -e "show databases like 'wordpress%'"`;
	do
		mkdir $db;
		for table in `$MYSQL -e "use $db;show tables;"`
			do
				echo "Db: $db, table: $table";
				`$MYSQLDMP --add-drop-table --add-locks --create-options --disable-keys --extended-insert --single-transaction --quick --set-charset --events --triggers --master-data=2 $db $table | gzip -1 > /var/backup/$db/$table.gz`;
			done
	done

