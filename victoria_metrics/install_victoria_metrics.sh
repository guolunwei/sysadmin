#!/bin/bash

set -e

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Extracting VictoriaMetrics..."
# wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.119.0/victoria-metrics-linux-amd64-v1.122.0.tar.gz
tar -xf victoria-metrics-linux-amd64-v1.122.0.tar.gz
mv victoria-metrics-prod /usr/local/bin

log "Adding VictoriaMetrics user..."
useradd -r -s /sbin/nologin vmuser
mkdir -p /opt/vm-data
chown -R vmuser:vmuser /opt/vm-data

log "Adding VictoriaMetrics service..."
cat > /etc/systemd/system/victoria-metrics.service << 'EOF'
[Unit]
Description=VictoriaMetrics Time Series Database
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/victoria-metrics-prod \
  -retentionPeriod=30 \
  -storageDataPath=/opt/vm-data \
  -httpListenAddr=:8428

User=vmuser
Group=vmuser
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

log "Reloading systemd and starting VictoriaMetrics service..."
systemctl daemon-reload
systemctl enable victoria-metrics
systemctl start victoria-metrics
systemctl status victoria-metrics
echo "VictoriaMetrics installed successfully."
