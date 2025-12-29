#!/bin/bash

JENKINS_HOME=/home/admin/jenkins
BACKUP_DIR=/opt/jenkins_backup
DATE=$(date +%Y-%m-%d)
KEEP_DAYS=5

mkdir -p $BACKUP_DIR

BACKUP_FILE="$BACKUP_DIR/jenkins_home_$DATE.tgz"

echo "Backing up Jenkins to $BACKUP_FILE..."

cd "$JENKINS_HOME" || exit
tar -zcf "$BACKUP_FILE" plugins jobs users secrets* ./*.xml -C "$HOME" .ssh

echo "Deleting archives older than $KEEP_DAYS days..."
find "$BACKUP_DIR" -type f -mtime +$KEEP_DAYS -exec rm -f {} \;

echo "Backup complete."
