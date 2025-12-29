#!/bin/bash
#
# This script is used to complie and install redis-6.2.11

set -eu

REDIS_VERSION=6.2.11
REDIS_URL=https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz

WORK_DIR=/usr/local/src
REDIS_DIR=$WORK_DIR/redis-${REDIS_VERSION}
SOURCE_DIR=$REDIS_DIR/src

if curl -I -fsL "$REDIS_URL" > /dev/ull; then
  curl -fSL --progress-bar "$REDIS_URL" | tar -xzf - -C /usr/local/src
fi

yum install -y gcc make

cd $SOURCE_DIR
make && make install

mkdir -p /etc/redis
cp $REDIS_DIR/redis.conf /etc/redis/redis.conf

IP_ADDR=$(ifconfig eth0 | grep -w inet | awk '{print $2}')

sed -i "s/daemonize no/daemonize yes/" /etc/redis/redis.conf
sed -i "s/bind 127.0.0.1 -::1/bind $IP_ADDR/" /etc/redis/redis.conf

cat > /etc/systemd/system/redis.service << EOF
[Unit]
Description=redis-server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl enable redis --now
