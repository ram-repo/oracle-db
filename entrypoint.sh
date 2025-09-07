#!/bin/bash
set -euo pipefail

ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
ORACLE_BASE=/opt/oracle
PATH=$ORACLE_HOME/bin:$PATH

# First-time configuration (must run as root, then fix perms)
if [ ! -d "/opt/oracle/oradata/XE" ]; then
  echo "Running first-time configure..."
  echo -e "${ORACLE_PASSWORD}\n${ORACLE_PASSWORD}" | /etc/init.d/oracle-xe-21c configure

  # Fix ownership so runtime oracle user can manage files
  chown -R oracle:oinstall $ORACLE_BASE
fi

# Drop to oracle and start services
exec gosu oracle bash -lc "
  export ORACLE_HOME=$ORACLE_HOME
  export PATH=\$ORACLE_HOME/bin:\$PATH
  lsnrctl start
  echo startup | sqlplus -s / as sysdba
  tail -f \$(find /opt/oracle/diag/rdbms -type f -name 'alert_*.log' | head -n1)
"
