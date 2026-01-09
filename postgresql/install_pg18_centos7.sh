#!/bin/bash
set -e

PG_VERSION=18.1
PG_HOME=/usr/local/pgsql18
PG_DATA=/home/postgres/pgdata
PG_USER=postgres

# must run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root"
  exit 1
fi

echo "Installing dependencies..."
yum install -y gcc bison flex libicu-devel readline-devel zlib-devel wget

echo "Downloading PostgreSQL..."
cd /usr/local/src
wget -q https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.gz

tar -xzf postgresql-$PG_VERSION.tar.gz
cd postgresql-$PG_VERSION

echo "Compiling PostgreSQL..."
./configure --prefix=$PG_HOME
make -j"$(nproc)"
make install

echo "Setting environment..."
cat << EOF > /etc/profile.d/pgsql.sh
export PATH=\$PATH:$PG_HOME/bin
EOF

echo "$PG_HOME/lib" > /etc/ld.so.conf.d/pgsql.conf
ldconfig

echo "Creating postgres user..."
id $PG_USER &> /dev/null || useradd -r -U -m $PG_USER

echo "Preparing data directory..."
mkdir -p $PG_DATA
chown -R $PG_USER:$PG_USER $PG_DATA
chmod 700 $PG_DATA

echo "Initializing database..."
runuser -u $PG_USER -- $PG_HOME/bin/initdb -D $PG_DATA

# create systemd service
echo "Creating systemd service..."
cat << EOF > /etc/systemd/system/postgresql-18.service
[Unit]
Description=PostgreSQL Server 18.1
After=network.target

[Service]
Type=forking
User=$PG_USER
Group=$PG_USER
Environment=PGDATA=$PG_DATA
ExecStart=$PG_HOME/bin/pg_ctl start -D \${PGDATA}
ExecStop=$PG_HOME/bin/pg_ctl stop -D \${PGDATA}
ExecReload=$PG_HOME/bin/pg_ctl reload -D \${PGDATA}
TimeoutSec=300
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable postgresql-18
systemctl start postgresql-18

echo "PostgreSQL $PG_VERSION installed successfully!"
systemctl status postgresql-18 --no-pager
