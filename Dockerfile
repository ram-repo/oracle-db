FROM oraclelinux:7-slim

ARG XE_RPM=oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm
ENV ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE \
    ORACLE_BASE=/opt/oracle \
    ORACLE_SID=XE \
    PATH=/opt/oracle/product/21c/dbhomeXE/bin:$PATH \
    ORA_INVENTORY=/opt/oraInventory \
    ORACLE_PASSWORD=ChangeMe123

# Copy Oracle XE RPM (must be present alongside Dockerfile)
COPY ${XE_RPM} /tmp/${XE_RPM}

# Install Oracle prerequisites, RPM, utilities, gosu
RUN yum -y install oracle-database-preinstall-21c \
    && yum -y localinstall /tmp/${XE_RPM} \
    && yum -y install which shadow-utils passwd procps-ng curl \
    && curl -L -o /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64 \
    && chmod +x /usr/local/bin/gosu \
    && rm -f /tmp/${XE_RPM} \
    && yum clean all

# Create oracle user & group explicitly (to align with K8s fsGroup)
RUN usermod -u 54321 oracle && groupmod -g 54321 oinstall

# Create necessary writable dirs with correct permissions
RUN mkdir -p ${ORACLE_BASE}/oradata \
           ${ORACLE_BASE}/diag \
           /u01 \
           /opt/oracle/cfgtoollogs \
    && chown -R oracle:oinstall ${ORACLE_BASE} /u01 /opt/oracle \
    && chmod -R 775 ${ORACLE_BASE} /u01 /opt/oracle

# Fix oradism binary (must be root-owned, suid bit set)
RUN chown root:oinstall ${ORACLE_HOME}/bin/oradism \
    && chmod 4750 ${ORACLE_HOME}/bin/oradism

# Copy entrypoint script
COPY entrypoint.sh /opt/oracle/docker-entrypoint.sh
RUN chmod +x /opt/oracle/docker-entrypoint.sh \
    && chown oracle:oinstall /opt/oracle/docker-entrypoint.sh

# Switch to oracle user by default (K8s non-root support)
USER oracle

# Expose DB and EM ports
EXPOSE 1521 5500

# Healthcheck (runs as oracle via gosu)
HEALTHCHECK --interval=30s --start-period=90s --timeout=10s --retries=10 \
  CMD echo 'select 1 from dual;' | sqlplus -s system/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/opt/oracle/docker-entrypoint.sh"]
CMD ["bash"]
