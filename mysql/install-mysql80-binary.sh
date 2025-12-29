#!/bin/bash

set -e

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

if [ $# -ne 1 ]; then
  echo "Usage: $0 <server_id>"
  exit 1
fi

SERVER_ID=$1

log "Adding mysql user..."
groupadd mysql
useradd -g mysql mysql
echo changeMe@123 | passwd --stdin mysql

log "Installing MySQL..."
# wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.20-linux-glibc2.12-x86_64.tar.xz
tar -xvf mysql-8.0.20-linux-glibc2.12-x86_64.tar.xz
mv mysql-8.0.20-linux-glibc2.12-x86_64 /usr/local/mysql-8.0.20
rm -rf mysql-8.0.20-linux-glibc2.12-x86_64.tar.xz

log "Making data directory..."
cd /usr/local/mysql-8.0.20/
mkdir data

log "Granting permissions..."
chown -R mysql.mysql /usr/local/mysql-8.0.20
chmod -R 750 /usr/local/mysql-8.0.20/data

log "Setting up MySQL environment variables..."
cat >> /etc/profile << EOF
export PATH=\$PATH:/usr/local/mysql-8.0.20/bin:/usr/local/mysql-8.0.20/lib
EOF
source /etc/profile

log "Adding my.cnf..."
cat > /etc/my.cnf << EOF
[mysql]
default-character-set=utf8mb4

[client]
port=3306
socket=/var/lib/mysql/mysql.sock

[mysqld]
server-id=$SERVER_ID

user=mysql
port=3306
socket=/var/lib/mysql/mysql.sock
wait_timeout= 86400
character-set-server=utf8mb4
lower_case_table_names=1
autocommit=1
default_authentication_plugin=mysql_native_password
symbolic-links=0
max-connections=600

basedir=/usr/local/mysql-8.0.20
datadir=/usr/local/mysql-8.0.20/data
innodb_data_home_dir=/usr/local/mysql-8.0.20/data
innodb_log_group_home_dir=/usr/local/mysql-8.0.20/data/

general_log = 1
general_log_file= /var/log/mariadb/general.log
log-bin=/var/log/mariadb/mysql-bin.log

# Disabling symbolic-links is recommended to prevent assorted security risks
# symbolic-links=0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d

EOF

log "Installing libaio..."
yum install -y libaio

log "Making /var/lib/mysql directory..."
mkdir /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql/

log "Creating log and run directories..."
mkdir /var/log/mariadb
chown -R mysql.mysql /var/log/mariadb/
cd /var/log/mariadb/
touch mariadb.log
chown -R mysql.mysql /var/log/mariadb/mariadb.log
chmod 774 /var/log/mariadb/mariadb.log

mkdir /var/run/mariadb
cd /var/run/mariadb/
touch mariadb.pid
chown -R mysql.mysql /var/run/mariadb/mariadb.pid
chmod 774 /var/run/mariadb/mariadb.pid

log "Initializing MySQL..."
cd /usr/local/mysql-8.0.20/bin
./mysqld --user=mysql --basedir=/usr/local/mysql-8.0.20 --datadir=/usr/local/mysql-8.0.20/data --initialize 2>&1 | tee /var/log/mariadb/mysql-init.log

echo "Initiated MySQL successfully."

log "Enabling start on boot..."
cd /usr/local/mysql-8.0.20/support-files
cp -a mysql.server /etc/init.d/mysql
cp -a mysql.server /etc/init.d/mysqld

log "Adding mysqld in chkconfig..."
chkconfig --add mysqld
chkconfig --list

log "Starting MySQL..."
service mysql start

log "Checking MySQL status..."
service mysql status

log "Setting up root password..."
temp_password=$(grep 'temporary password' /var/log/mariadb/mysql-init.log | awk '{print $NF}')
mysqladmin -uroot -p"$temp_password" password '123qqq..A'

echo "MySQL installed successfully."
