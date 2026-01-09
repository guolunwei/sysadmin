#!/bin/bash

set -e

PG_VERSION=18.1
PG_HOME=/usr/local/pgsql18

yum install -y gcc bison flex libicu-devel readline-devel zlib-devel

wget https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.gz

tar -xzf postgresql-$PG_VERSION.tar.gz

cd postgresql-$PG_VERSION
./configure --prefix=$PG_HOME
make -j"$(proc)" && make install

cat << EOF > /etc/profile.d/pgsql.sh
export PATH=\$PATH:$PG_HOME/bin
EOF

echo "$PG_HOME/lib" | tee /etc/ld.so.conf.d/pgsql.conf
ldconfig
ldconfig -p | grep libpq

useradd -r -U -m postgres
echo "pgadmin4" | passwd --stdin postgres
