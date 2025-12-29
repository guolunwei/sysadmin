#!/bin/bash

set -eu

SKYWALKING_JAVA_AGENT_VERSION=9.4.0
SKYWALKING_JAVA_AGENT_FILE=apache-skywalking-java-agent-$SKYWALKING_JAVA_AGENT_VERSION.tgz
SKYWALKING_JAVA_AGENT_URL=https://dlcdn.apache.org/skywalking/java-agent/$SKYWALKING_JAVA_AGENT_VERSION/$SKYWALKING_JAVA_AGENT_FILE

color() {
  RES_COL=60
  MOVE_TO_COL="echo -en \\033[${RES_COL}G"
  SETCOLOR_SUCCESS="echo -en \\033[1;32m"
  SETCOLOR_FAILURE="echo -en \\033[1;31m"
  SETCOLOR_WARNING="echo -en \\033[1;33m"
  SETCOLOR_NORMAL="echo -en \E[0m"
  echo -n "$1" && $MOVE_TO_COL
  echo -n "["
  if [ "$2" = "success" ] || [ "$2" = "0" ]; then
    ${SETCOLOR_SUCCESS}
    echo -n "  OK  "
  elif [ "$2" = "failure" ] || [ "$2" = "1" ]; then
    ${SETCOLOR_FAILURE}
    echo -n "FAILED"
  else
    ${SETCOLOR_WARNING}
    echo -n "WARNING"
  fi
  ${SETCOLOR_NORMAL}
  echo -n "]"
  echo
}

install_skywalking_java_agent() {
  if curl -I -fsL $SKYWALKING_JAVA_AGENT_URL > /dev/ull; then
    curl -fSL --progress-bar $SKYWALKING_JAVA_AGENT_URL | tar -xzf - -C /usr/local
  fi

  if [ $? -eq 0 ]; then
    color "SKYWALKING_JAVA_AGENT installed successfully" 0
    echo "--------------------------------------------------------------------"
    echo -e "\E[31;1m请按需修改配置文件: \n\E[32;1m/usr/local/src/skywalking-agent.config\E[0m"
    echo -e "\E[31;1m请按如下形式调用:
\E[32;1mjava -javaagent:/usr/local/src/skywalking-agent/skywalking-agent \\
     -DSW_AGENT_NAME=<service_name> \\
     -DSW_AGENT_COLLECTOR_BACKEND_SERVICES=<skywalking_server>:11800 \\
     -jar yourapp.jar\E[0m"
  else
    color "Skywalking java agent installed failed" 1
    exit 1
  fi
}

install_skywalking_java_agent
