#!/bin/bash

set -e

# Create the zookeeper configuration file if it does not exist.
function setupConfig() {
  local cfg="$ZOO_CONF_DIR/zoo.cfg"
  local server

  if [ ! -f "$cfg" ]
  then
    echo "clientPort=$ZOO_CLIENT_PORT" >> "$cfg"
    echo "dataDir=$ZOO_DATA_DIR" >> "$cfg"
    echo "dataLogDir=$ZOO_DATA_LOG_DIR" >> "$cfg"
    echo "initTime=$ZOO_INIT_TIME" >> "$cfg"
    echo "syncLimit=$ZOO_SYNC_LIMIT" >> "$cfg"
    echo "tickTime=$ZOO_TICK_TIME" >> "$cfg"
    for server in $ZOO_SERVERS
    do
      echo "$server" >> "$cfg"
    done
  fi
}

# Set the myid file if it does not exist.
function setMyId() {
  local myid=${ZOO_MY_ID:-"1"}
  if [ ! -f "$ZOO_DATA_DIR/myid" ]
  then
    echo "$myid" > "$ZOO_DATA_DIR/myid"
  fi
}

# if we are root, set ownership and restart as ZOO_USER
if [ "$1"x = "zkServer.sh"x -a "$(id -u)" = "0" ]
then
  chown -R "$ZOO_USER:$ZOO_USER" "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR"
  exec gosu "$ZOO_USER" "$0" "$@"
fi

setupConfig
setMyId

exec "$@"
