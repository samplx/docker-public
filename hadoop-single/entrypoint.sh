#!/bin/bash

HADOOP_HOME=${HADOOP_HOME:-"/usr/local/hadoop"}
HADOOP_CONF=${HADOOP_CONF_DIR:-"$HADOOP_HOME/etc/hadoop"}
HADOOP_PID_DIR=${HADOOP_PID_DIR:-"$HADOOP_HOME/run"}

HADOOP_USER=${HADOOP_USER:-"hadoop"}
HADOOP_USER_HOME=${HADOOP_USER_HOME:-"/home/$HADOOP_USER"}

. "$HADOOP_CONF/hadoop-env.sh"

function cleanup() {
  rm -f "$HADOOP_PID_DIR"/*.pid
  rm -f "$HADOOP_USER_HOME"/.ssh/known_hosts
}

function startSSHD() {
  /etc/init.d/ssh start
}

function setHostname() {
  if [ "$HOSTNAME"x != "x" ]
  then
    sed -e "s|HOSTNAME|$HOSTNAME|" "$HADOOP_CONF_DIR/core-site.xml.template" \
      > "$HADOOP_CONF_DIR/core-site.xml"
  fi
}

function startHadoop() {
  "$HADOOP_HOME/sbin/start-dfs.sh"
  "$HADOOP_HOME/sbin/start-yarn.sh"
  "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh" start historyserver
}

function waitLoop() {
  while true
  do
    sleep 3600
  done
}

if [ "$1"x = "bash"x ]
then
  exec /bin/bash
fi

if [ "$1"x = "-d"x ]
then
  if [ "$(id -u)" = "0" ]
  then
    startSSHD
    exec gosu "$HADOOP_USER" "$0" "$@"
  fi
  cleanup
  setHostname
  startHadoop
  waitLoop
fi
