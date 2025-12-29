#!/bin/bash

set -e
set -o pipefail

CLUSTER_NAME="elastic-cluster"
NODE_NAME="node-1"

# Add the Elasticsearch repository
cat << EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install Elasticsearch
sudo yum install -y elasticsearch

# Configure Elasticsearch
sudo cp -a /etc/elasticsearch/elasticsearch.yml{,.bak}
cat << EOF | sudo tee /etc/elasticsearch/elasticsearch.yml
cluster.name: $CLUSTER_NAME
node.name: $NODE_NAME

path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

network.host: 0.0.0.0
http.port: 9200

discovery.seed_hosts: []
cluster.initial_master_nodes: ["$NODE_NAME"]

xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
EOF

# Create the certificates
sudo mkdir -p /etc/elasticsearch/certs
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert \
  --out /etc/elasticsearch/certs/elastic-certificates.p12 \
  --pass ""

sudo chown -R elasticsearch:elasticsearch /etc/elasticsearch/certs
sudo chmod 750 /etc/elasticsearch/certs
sudo chmod 640 /etc/elasticsearch/certs/elastic-certificates.p12

# Configure JVM
cat << EOF | sudo tee /etc/elasticsearch/jvm.options.d/custom.options
-Xms4g
-Xmx4g
EOF

# Start and enable Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Post-install
echo "Installation complete. Use the following command to setup the Elasticsearch password:"
echo "sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive"
