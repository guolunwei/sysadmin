#!/bin/bash

set -eu

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

VERSION=1.19.10

log "Install dependencies..."
yum -y install gcc zlib zlib-devel pcre-devel openssl openssl-devel

log "Download nginx..."
if curl -I -fsL https://nginx.org/download/nginx-${VERSION}.tar.gz > /dev/null; then
  curl -fSL --progress-bar https://nginx.org/download/nginx-${VERSION}.tar.gz | tar -xzf - -C /usr/local/src
fi

log "Compile & install nginx..."
cd /usr/local/src/nginx-${VERSION}
./configure --prefix=/usr/local/nginx \
  --with-http_stub_status_module \
  --with-http_ssl_module \
  --with-stream
make -j"$(nproc)" && make -j"$(nproc)" install

log "Verifying nginx installation..."
if /usr/local/nginx/sbin/nginx -V; then
  log "Nginx installed successfully."
else
  log "Nginx installation failed."
  exit 1
fi

log "Installing nginx systemd service..."
cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PIDFile=/usr/local/nginx/logs/nginx.pid
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

log "Starting nginx..."
systemctl daemon-reload
systemctl enable nginx
systemctl start nginx

log "Verifying nginx service..."
if systemctl status nginx | grep -q "active (running)"; then
  log "Nginx service started successfully."
else
  log "Nginx service failed to start."
  exit 1
fi
