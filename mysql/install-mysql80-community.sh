#!/bin/bash

set -eu

if curl -I -fsL https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm > /dev/null; then
  wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
  rpm -ivh mysql80-community-release-el7-3.noarch.rpm
fi

yum install -y mysql-community-server --nogpgcheck
rm -f mysql80-community-release-el7-3.noarch.rpm

# start and initialize
systemctl enable mysqld --now
systemctl status mysqld
