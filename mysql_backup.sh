#!/bin/bash

# ===== CONFIG =====
SRC_DB="source_database"
SRC_USER="source_user"
SRC_PASS="source_password"

TABLES="table1 table2"
BACKUP_FILE="/root/db_backup_$(date +%F).sql.gz"

# VPS2 info
DEST_HOST="VPS2_IP"
DEST_USER="user"
DEST_DB="destination_database"
DEST_DB_USER="dbuser"
DEST_DB_PASS="dbpassword"
SSH_PORT=4420

# ===== Step 1: Dump and compress (DROP TABLE if exists) =====
mysqldump -u"$SRC_USER" -p"$SRC_PASS" "$SRC_DB" $TABLES \
  --single-transaction --quick --lock-tables=false --add-drop-table | gzip > "$BACKUP_FILE"

# ===== Step 2: Copy backup to VPS2 =====
scp -P $SSH_PORT "$BACKUP_FILE" "$DEST_USER@$DEST_HOST:/home/$DEST_USER/"

# ===== Step 3: Restore remotely (fresh tables) =====
ssh -p $SSH_PORT "$DEST_USER@$DEST_HOST" "
gunzip -c /home/$DEST_USER/$(basename "$BACKUP_FILE") | \
mysql -u$DEST_DB_USER -p$DEST_DB_PASS $DEST_DB
"

# ===== Step 4: Cleanup local backup =====
rm -f "$BACKUP_FILE"

# ===== Step 5: Logging =====
if [ $? -eq 0 ]; then
    echo \"$(date +'%F %T') - SUCCESS\" >> /var/log/mysql_table_sync.log
else
    echo \"$(date +'%F %T') - FAILED\" >> /var/log/mysql_table_sync.log
fi
