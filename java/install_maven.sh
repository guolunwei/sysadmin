#!/bin/bash

set -eu

STABLE_VERSION=$(curl -s https://repo1.maven.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml \
  | grep '<version>.*</version>' | grep -vE 'alpha|beta|rc' | tail -1 | grep -oP '(?<=<version>).*(?=</version>)')
echo "Installing Maven $STABLE_VERSION"
MAIN_VERSION=$(echo "$STABLE_VERSION" | cut -d. -f1)

MAVEN_URL=https://mirrors.aliyun.com/apache/maven/maven-$MAIN_VERSION/$STABLE_VERSION/binaries/apache-maven-$STABLE_VERSION-bin.tar.gz
MAVEN_HOME=/usr/local/apache-maven-$STABLE_VERSION

if curl -I -fsL $MAVEN_URL > /dev/null; then
  curl -fSL --progress-bar $MAVEN_URL | tar -xzf - -C /usr/local
else
  echo "Failed to download $MAVEN_URL"
  exit 1
fi

ln -sf "$MAVEN_HOME" /usr/local/maven

cat > /etc/profile.d/maven.sh << 'EOF'
export MAVEN_HOME=/usr/local/maven
export PATH=/usr/local/maven/bin:$PATH
EOF

echo "Installed Maven $STABLE_VERSION successfully"
echo "Please run 'source /etc/profile' to take effect"
