#!/bin/bash

set -eu

MAVEN_VERSION=3.9.11
MAVEN_URL=https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

MAVEN_HOME=/usr/local/apache-maven-$MAVEN_VERSION

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

echo "Installed Maven $MAVEN_VERSION successfully"
echo "Please run 'source /etc/profile' to take effect"
