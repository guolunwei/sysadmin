#!/bin/bash

cat > /etc/docker/daemon.json <<- 'EOF'
{
    "registry-mirrors": [ "https://91efa3ce47eb43a387110210186f8803.mirror.swr.myhuaweicloud.com" ]
}
EOF

systemctl restart docker
