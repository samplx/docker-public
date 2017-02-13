#!/bin/bash


MYSQLD=${MYSQLD:-"/usr/sbin/mysqld"}
MYSQL=${MYSQL:-"/usr/bin/mysql"}
MYSQLADMIN=${MYSQLADMIN:-"/usr/bin/mysqladmin"}

MAX_RETRIES=${MAX_RETRIES:-"25"}
RETRY_SLEEP=${RETRY_SLEEP:-"1"}
TMPDIR=${TMPDIR:-"/tmp"}

function checkMysqld() {
  "$MYSQLD" --verbose --help > /dev/null 2>&1
  if [ "$?" -ne 0 ]
  then
    echo "ERROR: Unable to execute $MYSQLD."
    exit 1
  fi
}

function getDataDir() {
  "$MYSQLD" --verbose --help 2> /dev/null | \
    grep '^datadir' | \
      awk '{ print $2 }'
}

function getRootPassword() {
  if [ "$MYSQL_ROOT_PASSWORD"x != "x" ]
  then
    if [ -f "$MYSQL_ROOT_PASSWORD" ]
    then
      MYSQL_ROOT_PASSWORD="$(cat $MYSQL_ROOT_PASSWORD)"
    fi
  elif [ "$MYSQL_RANDOM_ROOT_PASSWORD"x = "yes"x ]
  then
    MYSQL_ROOT_PASSWORD=$(pwmake 128)
    echo "Generated ROOT password: ${MYSQL_ROOT_PASSWORD}"
  else
    echo 'ERROR: Database is not intialized and password option is not set.' 1>&2
    echo '  set either MYSQL_ROOT_PASSWORD or MYSQL_RANDOM_ROOT_PASSWORD=yes' 1>&2
    exit 1
  fi
}

function installDatabase() {
  echo 'Executing mysql_install_db...'
  mysql_install_db --user=mysql --datadir="$DATADIR"
  echo 'Done.'
}

function checkInit() {
  echo 'Awaiting startup...'
  local i=0
  while [ "$i" -lt "$MAX_RETRIES" ]
  do
    if echo 'SELECT 1;' | $MYSQL_COMMAND > /dev/null 2>&1
    then
      break
    fi
    sleep "$RETRY_SLEEP"
    i=$((i+1))
  done
  if [ "$i" -eq "$MAX_RETRIES" ]
  then
    echo 'ERROR: Database initialization failed.' 1>&2
    exit 1
  fi
  echo 'Done.'
}

function importZoneinfo() {
  echo 'Importing zoneinfo...'
  mysql_tzinfo_to_sql /usr/share/zoneinfo | $MYSQL_COMMAND mysql
  echo 'Done.'
}

function initMysqlDatabase() {
  local tempFile=$(mktemp)
  if [ ! -f "$tempFile" ]
  then
    echo 'ERROR: Unable to create temporary file.' 1>&2
    exit 1
  fi
  cat << EOF > $tempFile
    SET @@SESSION.SQL_LOG_BIN=0;
    DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR (host != 'localhost');
    SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}');
    DROP DATABASE IF EXISTS test;
    FLUSH PRIVILEGES;
EOF
  $MYSQL_COMMAND < $tempFile
  rm -f $tempFile
}

function setRootPassword() {
  echo 'Setting root password...'
  "$MYSQLADMIN" -u root password "$MYSQL_ROOT_PASSWORD"
  echo 'Done.'
}

function initUserDatabase() {
  echo 'Initializing user database (if any)...'
  local tempFile=$(mktemp)
  if [ ! -f "$tempFile" ]
  then
    echo 'ERROR: Unable to create temporary file.' 1>&2
    exit 1
  fi

  if [ "$MYSQL_DATABASE"x != "x" ]
  then
    echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;" >> $tempFile
  fi
  if [ "$MYSQL_USER"x != "x" -a "$MYSQL_PASSWORD"x != "x" ]
  then
    echo "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';" >> $tempFile
    if [ "$MYSQL_DATABASE"x != "x" ]
    then
      echo "GRANT ALL ON \'${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';" >> $tempFile
    fi
  fi
  echo 'FLUSH PRIVILEGES;' >> $tempFile

  $MYSQL_COMMAND < $tempFile
  rm -f $tempFile
  echo 'Done.'
}

# usage setupMysql yes|no
#   yes if we are starting from nothing, no if $DATADIR existed.
function setupMysql() {
  local full="$1"
  local pid

  echo 'MySQL setup started...'
  getRootPassword

  mkdir -p "$DATADIR"
  chown -R mysql:mysql "$DATADIR"

  installDatabase

  "$MYSQLD" --skip-networking --socket=/var/run/mysqld/mysqld.sock &
  pid="$!"

  MYSQL_COMMAND="$MYSQL --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock"

  checkInit

  if [ "$full"x != "yes"x ]
  then
    setRootPassword
  else
    importZoneinfo

    initMysqlDatabase
  fi

  MYSQL_COMMAND="$MYSQL_COMMAND -p${MYSQL_ROOT_PASSWORD}"

  initUserDatabase

  if ! kill -s TERM "$pid" || ! wait "$pid"
  then
    echo 'ERROR: setup process failed.' 1>&2
    exit 1
  fi

  chown -R mysql:mysql "$DATADIR"

  echo 'MySQL setup completed.'
}

if [ "$1"x = "bash"x ]
then
  exec /bin/bash
fi

checkMysqld

set -e

DATADIR=$(getDataDir)
if [ ! -d "$DATADIR/mysql" ]
then
  setupMysql yes
elif [ "$1"x = "setup"x ]
then
  setupMysql no
  shift
fi

exec "$MYSQLD" "$@"
