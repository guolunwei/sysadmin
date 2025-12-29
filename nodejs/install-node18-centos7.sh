#!/bin/bash
#
# This script is only support running on CentOS 7.9 2009

set -e

upgrade_make() {
  if [ "$(make -v | grep -i make | awk '{print $NF}')" = "4.2" ]; then
    return
  fi

  make -v
  echo "============================================"

  # Download
  cd /usr/src
  if [ ! -f make-4.2.tar.gz ]; then
    wget http://ftp.gnu.org/pub/gnu/make/make-4.2.tar.gz
  fi

  # Compile and install
  tar -xf make-4.2.tar.gz
  cd make-4.2
  ./configure
  make -j16
  make install
  cd /usr/bin
  mv make{,.bak}
  cp /usr/local/bin/make .

  echo "============================================"
  make -v
}

upgrade_gcc() {
  if command -v gcc &> /dev/null; then
    GCC_VERSION=$(gcc --version | grep -i gcc | awk '{print $3}')

    if [ "$GCC_VERSION" = "8.1.0" ]; then
      return 0
    fi

    gcc --version
    echo "============================================"
  fi

  # Download
  cd /usr/src
  if [ ! -f gcc-8.1.0.tar.gz ]; then
    wget http://www.netgull.com/gcc/releases/gcc-8.1.0/gcc-8.1.0.tar.gz
  fi

  # Install dependencies
  yum install -y gcc gcc-c++ gcc-gnat libgcc libgcc.i686 glibc-devel bison flex texinfo \
    build-essential zlib-devel bzip2 file texinfo m4 openssl-devel openssl-libs openssl boost

  # Compile and install
  tar -xf gcc-8.1.0.tar.gz
  cd gcc-8.1.0
  ./contrib/download_prerequisites
  mkdir build
  cd build
  ../configure --enable-bootstrap --enable-checking=release --enable-languages=c,c++ --disable-multilib
  make -j16
  make install
  cd /usr/bin
  mv gcc gcc.bak
  cp /usr/local/bin/gcc .

  # Link newst dynamic libray
  find / -name "libstdc++.so*"
  cp /usr/src/gcc-8.1.0/build/stage1-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.25 /usr/lib64
  cd /usr/lib64
  ls -lh libstdc++.so.6
  mv libstdc++.so.6{,.bak}
  ln -sv libstdc++.so.6.0.25 libstdc++.so.6
  ls -lh libstdc++.so.6

  echo "============================================"
  gcc --version
}

upgrade_python() {
  if [ "$(python -V 2>&1 | awk '{print $NF}')" = '3.8.0' ]; then # In Python 2.x, the output redirects to stderr
    return
  fi

  python -V
  echo "============================================"

  # Download
  cd /usr/src
  if [ ! -f Python-3.8.0.tar.xz ]; then
    wget https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
  fi

  # Install dependencies
  yum install -y zlib-devel openssl-devel ncurses-devel readline-devel tk-devel gdbm-devel db4-devel

  # Compile and install
  tar -xf Python-3.8.0.tar.xz
  cd Python-3.8.0
  ./configure --prefix=/usr/local/python3.8.0
  make -j16
  make install
  mv /usr/bin/python /usr/bin/python2.7.5
  ln -sv /usr/local/python3.8.0/bin/python3 /usr/bin/python
  ln -sv /usr/local/python3.8.0/bin/pip3 /usr/bin/pip

  # Environemt  variable
  echo 'export PATH=/usr/local/python3.8.0/bin:$PATH' >> /etc/profile.d/python3.8.0.sh

  # Fix yum error
  sed -i 's|#!/usr/bin/python|#!/usr/bin/python2.7.5|' /usr/bin/yum
  sed -i 's|#! /usr/bin/python|#! /usr/bin/python2.7.5|' /usr/libexec/urlgrabber-ext-down

  echo "============================================"
  python -V
}

upgrade_glibc() {
  if [ "$(ldd --version | grep -i ldd | awk '{print $NF}')" = '2.30' ]; then
    return
  fi

  ldd --version
  echo "============================================"

  # Download
  cd /usr/src
  if [ ! -f glibc-2.30.tar.xz ]; then
    wget http://ftp.gnu.org/pub/gnu/glibc/glibc-2.30.tar.xz
  fi

  # Install dependencies
  yum install -y bison texinfo
  bison -V

  # Compile and install
  tar -xf glibc-2.30.tar.xz
  cd glibc-2.30
  mkdir build
  cd build
  ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
  make -j16
  make install || true # ignore error

  echo "============================================"
  ldd --version
}

check_env() {
  echo "Checking environment..."

  if [ "$(make -v | grep -i make | awk '{print $NF}')" != "4.2" ]; then
    echo "Please install make 4.2 first"
    exit 1
  fi

  if [ "$(gcc --version | grep -i gcc | awk '{print $3}')" != '8.1.0' ]; then
    echo "Please install gcc 8.1.0 first"
    exit 1
  fi

  if [ "$(python -V | awk '{print $NF}')" != '3.8.0' ]; then
    echo "Please install Python 3.8.0 first"
    exit 1
  fi

  if [ "$(ldd --version | grep -i ldd | awk '{print $NF}')" != '2.30' ]; then
    echo "Please install glibc 2.30 first"
    exit 1
  fi

  echo "Environment check complete"
}

install_node() {
  # Download
  cd /usr/src
  if [ ! -f node-v18.18.0-linux-x64.tar.gz ]; then
    wget https://nodejs.org/dist/v18.18.0/node-v18.18.0-linux-x64.tar.gz
  fi

  # Install
  tar -xf node-v18.18.0-linux-x64.tar.gz -C /usr/local
  cd /usr/local
  ln -sv node-v18.18.0-linux-x64 node
  ls node

  # Set Environment variables
  cat > /etc/profile.d/nodejs.sh << 'EOF'
export NODE_HOME=/usr/local/node
export PATH=$NODE_HOME/bin:$PATH
export NODE_PATH=$NODE_HOME/lib/node_modules
EOF

  source /etc/profile

  echo "============================================"
  node -v
  npm -v
}

install_yarn() {
  npm install -g yarn
  yarn -v
  echo "============================================"

  # Set yarn registry
  yarn config set registry https://registry.npmmirror.com/
  yarn config list
}

upgrade_deps() {
  if [ -f /usr/local/node ]; then
    return
  fi

  upgrade_gcc
  upgrade_make
  upgrade_python
  upgrade_glibc
}

upgrade_deps
check_env
install_node
install_yarn
