#!/bin/bash
#
# This script is used to install percona-xtrabackup on CentOS 7 with glibc 2.17.

set -eu

XTRABACKUP_URL=https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-8.0.35-31/binary/tarball/percona-xtrabackup-8.0.35-31-Linux-x86_64.glibc2.17-minimal.tar.gz

if curl -I -fsL $XTRABACKUP_URL > /dev/null; then
  curl -fSL --progress-bar $XTRABACKUP_URL | tar -xzf - -C /usr/local
fi

cat >> ~/.bashrc << 'EOF'
export PATH=percona-xtrabackup-8.0.35-31-Linux-x86_64.glibc2.17-minimal/bin:$PATH
EOF

echo "Please run  'source ~/.bashrc' to refresh your environment variables"
