FROM centos:7
#MAINTAINER Sean Cline <smcline06@gmail.com>

## --- ENV ---
ENV \
    CACTI_VERSION=1.2.8 \
    DB_NAME=cacti \
    DB_USER=cactiuser \
    DB_PASS=cactipassword \
    DB_HOST=localhost \
    DB_PORT=3306 \
    RDB_NAME=cacti \
    RDB_USER=cactiuser \
    RDB_PASS=cactipassword \
    RDB_HOST=localhost \
    RDB_PORT=3306 \
    BACKUP_RETENTION=7 \
    BACKUP_TIME=0 \
    SNMP_COMMUNITY=public \
    REMOTE_POLLER=0 \
    INITIALIZE_DB=0 \
    INITIALIZE_INFLUX=0 \
    TZ=UTC \
    PHP_MEMORY_LIMIT=800M \
    PHP_MAX_EXECUTION_TIME=60

## --- SUPPORTING FILES ---
#COPY cacti /cacti_install


## --- SCRIPTS ---
COPY upgrade.sh /upgrade.sh
COPY restore.sh /restore.sh
COPY backup.sh /backup.sh
## --- CACTI ---

RUN \
    chmod +x /upgrade.sh && \
    chmod +x /restore.sh && \
    chmod +x /backup.sh  && \
    mkdir /backups && \
    \
    rpm --rebuilddb && yum clean all && \
    yum update -y && \
    yum install -y \
        rrdtool net-snmp net-snmp-utils cronie php-ldap php-devel mysql php \
        ntp bison php-cli php-mysql php-common php-mbstring php-snmp curl \
        php-gd openssl openldap mod_ssl php-pear net-snmp-libs php-pdo \
        autoconf automake gcc gzip help2man libtool make net-snmp-devel \
        m4 libmysqlclient-devel libmysqlclient openssl-devel dos2unix wget \
        sendmail mariadb-devel which && \
    yum clean all && \
    \
    echo "Download, extracting and installing Cacti files to /cacti." && \
    mkdir /cacti_install && \
    curl -L -o /cacti_install/cacti-${CACTI_VERSION}.tgz https://github.com/Cacti/cacti/archive/release/${CACTI_VERSION}.tar.gz && \
    mkdir -p /cacti && \
    tar zxvf /cacti_install/cacti-${CACTI_VERSION}.tgz -C /cacti --strip-components=1 && \
    \
    echo "Download, extracting and installing Spine files to /spine." && \
    curl -L -o /tmp/spine-${CACTI_VERSION}.tgz https://github.com/Cacti/spine/archive/release/${CACTI_VERSION}.tar.gz && \
    mkdir -p /tmp/spine && \
    mkdir -p /spine   && \
    tar zxvf /tmp/spine-${CACTI_VERSION}.tgz -C /tmp/spine --strip-components=1 && \
    rm -f /tmp/spine-${CACTI_VERSION}.tgz && \
    cd /tmp/spine && ./bootstrap && ./configure --prefix=/spine && make && make install && \
    chown root:root /spine/bin/spine && \
    chmod +s /spine/bin/spine && \
    rm -rf /tmp/spine && \
    \
    echo "Fix cron issues - https://github.com/CentOS/CentOS-Dockerfiles/issues/31" && \
    sed -i '/session required pam_loginuid.so/d' /etc/pam.d/crond && \
    \
    echo "misc setup" && \
    echo "ServerName localhost" > /etc/httpd/conf.d/fqdn.conf

## --- SERVICE CONFIGS ---
COPY configs /template_configs

## --- SETTINGS/EXTRAS ---
COPY plugins /cacti_install/plugins
COPY templates /templates
COPY settings /settings

## --- Start ---
COPY start.sh /start.sh
CMD ["/start.sh"]

EXPOSE 80 443
