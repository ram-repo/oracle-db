# Dockerfile - Oracle XE 21c (runtime as non-root oracle)
FROM oraclelinux:7-slim

ARG XE_RPM=oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm
ENV ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE \
    ORACLE_BASE=/opt/oracle \
    ORACLE_SID=XE \
    PATH=/opt/oracle/product/21c/dbhomeXE/bin:$PATH \
    ORA_INVENTORY=/opt/oraInventory

# Copy RPM (must be placed alongside Dockerfile)
COPY ${XE_RPM} /tmp/${XE_RPM}

# Install prerequisites, rpm, gosu, and cleanup
RUN yum -y install oracle-database-preinstall-21c \
    && yum -y localinstall /tmp/${XE_RPM} \
    && yum -y install which shadow-utils passwd procps-ng curl \
    && curl -L -o /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64 \
    && chmod +x /usr/local/bin/gosu \
    && rm -f /tmp/${XE_RPM} \
    && yum clean all
# Create only writable dirs and adjust ownership
RUN mkdir -p ${ORACLE_BASE}/oradata \
           ${ORACLE_BASE}/diag \
           /u01 \
           /opt/oracle/cfgtoollogs \
    && chown -R oracle:oinstall ${ORACLE_BASE}/oradata \
                               ${ORACLE_BASE}/diag \
                               /u01 \
                               /opt/oracle/cfgtoollogs \
    && chmod -R 775 ${ORACLE_BASE}/oradata \
                    ${ORACLE_BASE}/diag \
                    /u01 \
                    /opt/oracle/cfgtoollogs

# Fix oradism (root must own it, with SUID)
RUN chown root:oinstall ${ORACLE_HOME}/bin/oradism \
    && chmod 4750 ${ORACLE_HOME}/bin/oradism


# Copy entrypoint
COPY entrypoint.sh /opt/oracle/docker-entrypoint.sh
RUN chmod +x /opt/oracle/docker-entrypoint.sh

# Expose DB and EM ports
EXPOSE 1521 5500

# Healthcheck
HEALTHCHECK --interval=15s --start-period=60s --timeout=5s --retries=10 \
  CMD echo 'select 1 from dual;' | gosu oracle sqlplus -s system/${ORACLE_PASSWORD:-ChangeMe123}@//localhost:1521/XEPDB1 >/dev/null 2>&1 || exit 1

# Entrypoint: starts as root → drops to oracle
ENTRYPOINT ["/opt/oracle/docker-entrypoint.sh"]

CMD ["bash"]
