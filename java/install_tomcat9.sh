#!/bin/bash
# Single-instance Tomcat 9 installation script

set -e

# Variables
TOMCAT_VERSION=9.0.113
TOMCAT_PACKAGE="apache-tomcat-$TOMCAT_VERSION"
TOMCAT_URL="https://mirrors.aliyun.com/apache/tomcat/tomcat-9/v$TOMCAT_VERSION/bin/$TOMCAT_PACKAGE.tar.gz"

INSTALL_DIR=/usr/local
TOMCAT_DIR="$INSTALL_DIR/$TOMCAT_PACKAGE"
CATALINA_HOME="$INSTALL_DIR/tomcat"
TOMCAT_USER=tomcat
TOMCAT_GROUP=tomcat
UNIT_FILE="/etc/systemd/system/tomcat.service"

# 1. Install Java if missing
if ! command -v java > /dev/null 2>&1; then
  echo "Installing Java 8..."
  yum install -y java-1.8.0-openjdk-devel
fi

# 2. Download and extract Tomcat
if [ ! -d "$TOMCAT_DIR" ]; then
  echo "Downloading and extracting Tomcat..."
  if curl -I -fsL $TOMCAT_URL > /dev/null; then
    curl -fSL --progress-bar $TOMCAT_URL | tar -xzf - -C $INSTALL_DIR
    ln -sf "$TOMCAT_DIR" "$CATALINA_HOME"
  else
    echo "Failed to download Tomcat from $TOMCAT_URL"
    exit 1
  fi
fi

# 3. Create tomcat user if missing
if ! id $TOMCAT_USER > /dev/null 2>&1; then
  echo "Creating tomcat user..."
  useradd -r -s /sbin/nologin $TOMCAT_USER
fi

# 4. Ensure Tomcat files are owned by 'tomcat' and scripts are executable
chown -R $TOMCAT_USER:$TOMCAT_GROUP "$TOMCAT_DIR"
chmod -R u+rX "$TOMCAT_DIR"
chmod +x "$TOMCAT_DIR/bin/"*.sh

# 5. Create systemd unit
if [ ! -f "$UNIT_FILE" ]; then
  echo "Creating systemd service..."
  cat > "$UNIT_FILE" << 'EOF'
[Unit]
Description=Tomcat
After=network.target syslog.target

[Service]
Type=forking

User=tomcat
Group=tomcat

WorkingDirectory=/usr/local/tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_PID=/usr/local/tomcat/run/tomcat.pid"
Environment="CATALINA_BASE=/usr/local/tomcat"
Environment="CATALINA_HOME=/usr/local/tomcat"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/bin/bash /usr/local/tomcat/bin/startup.sh
ExecStop=/bin/bash /usr/local/tomcat/bin/shutdown.sh

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
fi

# 6. Reload systemd
systemctl daemon-reload

# 7. Start and enable service
systemctl start tomcat
systemctl enable tomcat

# 8. Show status
systemctl status tomcat --no-pager
