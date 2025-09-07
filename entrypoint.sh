#!/bin/bash
set -e

# Run configure only if DB not initialized
if [ ! -d "/opt/oracle/oradata/XE" ]; then
  echo "Configuring Oracle XE for first run..."
  echo -e "${ORACLE_PASSWORD}\n${ORACLE_PASSWORD}" | /etc/init.d/oracle-xe-21c configure
fi

echo "Starting Oracle XE..."
/etc/init.d/oracle-xe-21c start

# Drop to oracle user for long running process
exec su - oracle -c "tail -f /opt/oracle/diag/rdbms/*/*/alert*.log"

# set -e

# echo "Starting Oracle XE as oracle user..."

# # Drop to oracle
# exec gosu oracle bash -c "
#   $ORACLE_HOME/bin/lsnrctl start &&
#   echo 'Startup database...' &&
#   echo 'startup;' | sqlplus -s / as sysdba &&
#   tail -f /opt/oracle/diag/rdbms/*/*/alert*.log
# "
