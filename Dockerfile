# Zabbix version 2.4.5

# Pull base image
FROM ubuntu:14.04

MAINTAINER Nickolai Barnum <nbarnum@users.noreply.github.com>

ENV ZABBIX_VERSION trunk

# Install Zabbix and dependencies
RUN \
  apt-get update && apt-get install -y software-properties-common wget && \
  apt-add-repository universe && apt-add-repository multiverse && apt-get update && \
  apt-get install -y tar subversion gcc automake make nmap traceroute iptstate wget \
              libsnmp-dev snmp libsnmp-base libsnmp30 libsnmp-perl \
              python-netsnmp snmpd tkmib python-pip pkg-config \
              libxml2-dev gettext libiksemel3 \
              libssh2-1-dev \
              unixODBC unixODBC-dev \
              net-tools snmptt sudo && \
  svn co svn://svn.zabbix.com/${ZABBIX_VERSION} /usr/local/src/zabbix && \
  cd /usr/local/src/zabbix && \
  #wget http://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+trusty_all.deb \
       #-O /tmp/zabbix-release_${ZABBIX_VERSION}-1+trusty_all.deb  && \
  #dpkg -i /tmp/zabbix-release_${ZABBIX_VERSION}-1+trusty_all.deb && \
  #apt-add-repository multiverse && apt-get update && \
  apt-get install -y monit \
                     snmp-mibs-downloader \
                     sqlite3 \
                     libsqlite3-dev && \
  ./bootstrap.sh && \
  ./configure --prefix=/usr --enable-proxy --enable-ipv6 --with-net-snmp --with-sqlite3 --with-ssh2 && \
  make dbschema && \
  make install && \
  mkdir -p /var/lib/sqlite && \
  sqlite3 /var/lib/sqlite/zabbix.db < database/sqlite3/schema.sql && \
  wget https://github.com/schweikert/fping/archive/3.10.tar.gz && \
  tar -xvf 3.10.tar.gz && \
  cd fping-3.10/ && \
  ./autogen.sh && \
  ./configure --prefix=/usr --enable-ipv6 --enable-ipv4 && \
  make && \
  make install && \
  setcap cap_net_raw+ep /usr/sbin/fping || echo 'Warning: setcap cap_net_raw+ep /usr/sbin/fping' && \
  setcap cap_net_raw+ep /usr/sbin/fping6 || echo 'Warning: setcap cap_net_raw+ep /usr/sbin/fping6' && \
  chmod 4710 /usr/sbin/fping && \
  chmod 4710 /usr/sbin/fping6 && \
  rm -rf fping-3.10 && \
  rm -rf 3.10.tar.gz && \
  apt-get autoremove -y && apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy scripts, Monit config and Zabbix config into place
COPY monitrc                     /etc/monit/monitrc
COPY ./scripts/entrypoint.sh     /bin/docker-zabbix
COPY ./zabbix/zabbix_proxy.conf  /etc/zabbix/zabbix_proxy.conf

# Fix permissions
RUN chmod 755 /bin/docker-zabbix && \
    chmod 600 /etc/monit/monitrc && \
    chown zabbix:zabbix /var/lib/sqlite

# Expose ports for
# * 10051 zabbix_proxy
EXPOSE 10051

# Will run `/bin/docker run`, which instructs
# monit to start zabbix_proxy.
ENTRYPOINT ["/bin/docker-zabbix"]
CMD ["run"]
