#!/bin/bash
# This script installs Python 3.11.4 on CentOS 7.

install_dependencies() {
  yum -y groupinstall "Development Tools" --nogpgcheck
  yum -y install gcc openssl-devel bzip2-devel libffi-devel python3-devel sqlite-devel --nogpgcheck
}

install_openssl_1_1_1() {
  if curl -I -fsL https://dtse-mirrors.obs.cn-north-4.myhuaweicloud.com/case/0014/openssl-1.1.1t.tar.gz > /dev/null; then
    curl -fSL --progress-bar https://dtse-mirrors.obs.cn-north-4.myhuaweicloud.com/case/0014/openssl-1.1.1t.tar.gz | tar -xzf - -C /usr/local/src
    cd /usr/local/src/openssl-1.1.1t || exit
    ./config --prefix=/usr/local/openssl-1.1.1 --openssldir=/usr/local/openssl-1.1.1 shared zlib
    make -j"$(nproc)" && make -j"$(nproc)" install
    echo "/usr/local/openssl-1.1.1/lib" > /etc/ld.so.conf.d/openssl-1.1.1.conf
    ldconfig
  fi
}

install_python_3_11_4() {
  if curl -I -fsL https://mirrors.huaweicloud.com/python/3.11.4/Python-3.11.4.tar.xz > /dev/null; then
    curl -fSL --progress-bar https://mirrors.huaweicloud.com/python/3.11.4/Python-3.11.4.tar.xz | tar -xJf - -C /usr/local/src
    cd /usr/local/src/Python-3.11.4 || exit
    ./configure --prefix=/usr/local/python3.11.4 --with-openssl=/usr/local/openssl-1.1.1
    make -j"$(nproc)" && make -j"$(nproc)" install
    ln -sf /usr/local/python3.11.4/bin/python3.11 /usr/bin/python3
    [ -f /usr/bin/pip3 ] && mv /usr/bin/pip3{,.bak}
    ln -s /usr/local/python3.11.4/bin/pip3 /usr/bin/pip3
    python3 -m pip install --upgrade pip
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
  fi
}

install_dependencies
install_openssl_1_1_1
install_python_3_11_4
