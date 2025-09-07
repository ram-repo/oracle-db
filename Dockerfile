FROM oraclelinux:7-slim

# Copy RPM
COPY oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm /tmp/

# Install dependencies and XE
RUN yum -y install oracle-database-preinstall-21c && \
    yum -y localinstall /tmp/oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm && \
    rm -f /tmp/oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm && \
    yum clean all

# # Create non-root user
# RUN groupadd -g 1001 oracle && \
#     useradd -u 1001 -g oracle -m -s /bin/bash oracle && \
#     chown -R oracle:oracle /opt/oracle /u01

# Oracle env vars
ENV ORACLE_PASSWORD=Welcome123 \
    ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE \
    ORACLE_SID=XE \
    PATH=$PATH:/opt/oracle/product/21c/dbhomeXE/bin

# Copy startup script
COPY entrypoint.sh /opt/oracle/
RUN chmod +x /opt/oracle/entrypoint.sh

# USER oracle

ENTRYPOINT ["/opt/oracle/entrypoint.sh"]

EXPOSE 1521 5500
