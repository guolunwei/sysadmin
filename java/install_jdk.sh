#!/bin/bash
#
# This script installs openjdk 8/11/17 on CentOS 7 and sets it as default via alternatives

set -e

case $1 in
  17)
    JDK17_URL=https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz
    if curl -I -fsL $JDK17_URL > /dev/null; then
      echo "Installing oracleJDK 17..."
      curl -fSL --progress-bar $JDK17_URL | tar -xzf - -C /usr/local
      ln -sf /usr/local/jdk-17.0.12 /usr/local/jdk

      JDK17_JAVA_PATH="/usr/local/jdk-17.0.12/bin/java"
      JDK17_JAVAC_PATH="/usr/local/jdk-17.0.12/bin/javac"

      ls "$JDK17_JAVA_PATH"
      ls "$JDK17_JAVAC_PATH"

      update-alternatives --install /usr/bin/java java "$JDK17_JAVA_PATH" 1700
      update-alternatives --install /usr/bin/javac javac "$JDK17_JAVAC_PATH" 1700

      update-alternatives --set java "$JDK17_JAVA_PATH"
      update-alternatives --set javac "$JDK17_JAVAC_PATH"
    fi
    ;;
  11)
    echo "Installing OpenJDK 11..."
    yum install -y java-11-openjdk-devel > /dev/null 2>&1

    JDK11_JAVA_PATH=$(update-alternatives --display java | grep java-11 | grep priority | awk '{print $1}')
    JDK11_JAVAC_PATH=$(update-alternatives --display javac | grep java-11 | grep priority | awk '{print $1}')

    ls "$JDK11_JAVA_PATH"
    ls "$JDK11_JAVAC_PATH"

    update-alternatives --set java "$JDK11_JAVA_PATH"
    update-alternatives --set javac "$JDK11_JAVAC_PATH"
    ;;
  8)
    echo "Installing OpenJDK 8..."
    yum install -y java-1.8.0-openjdk-devel > /dev/null 2>&1

    JDK8_JAVA_PATH=$(update-alternatives --display java | grep java-1.8 | grep priority | awk '{print $1}')
    JDK8_JAVAC_PATH=$(update-alternatives --display javac | grep java-1.8 | grep priority | awk '{print $1}')

    ls "$JDK8_JAVA_PATH"
    ls "$JDK8_JAVAC_PATH"

    update-alternatives --set java "$JDK8_JAVA_PATH"
    update-alternatives --set javac "$JDK8_JAVAC_PATH"
    ;;
  *)
    echo "Usage: $0 {8,11,17}"
    ;;
esac
