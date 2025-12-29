#!/bin/bash
#
# This script is used to install percona-xtrabackup on CentOS 7 with rpm packages.

set -eu

echo "Install percona xtrabackup..."

if ! (yum list installed 2> /dev/null | grep -q percona-release-latest); then
  sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
fi
sudo percona-release setup ps80
sudo yum install -y percona-xtrabackup-80
