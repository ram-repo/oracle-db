#!/bin/bash
set -euo pipefail

ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
ORACLE_BASE=/opt/oracle
PATH=$ORACLE_HOME/bin:$PATH

DATA_DIR="$ORACLE_BASE/oradata/XE"

# First-time configuration (requires root, then fix perms)
if [ ! -d "$DATA_DIR" ]; then
  echo "Running first-time configure..."
  gosu root bash -c "echo -e \"${ORACLE_PASSWORD}\n${ORACLE_PASSWORD}\" | /etc/init.d/oracle-xe-21c configure"

  # Ensure oracle owns all runtime dirs
  gosu root chown -R oracle:oinstall $ORACLE_BASE
fi

# Drop to oracle and start services
exec gosu oracle bash -lc "
  export ORACLE_HOME=$ORACLE_HOME
  export PATH=\$ORACLE_HOME/bin:\$PATH

  # Start listener and database
  lsnrctl start
  echo 'startup' | sqlplus -s / as sysdba

  # Tail the main alert log
  tail -f \$(find /opt/oracle/diag/rdbms -type f -name 'alert_*.log' | head -n1)
"
