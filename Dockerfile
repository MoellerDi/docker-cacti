FROM centos:7
MAINTAINER nobody <nobody@nowhere.com>

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
    TZ=Europe/Berlin \
    PHP_MEMORY_LIMIT=800M \
    PHP_MAX_EXECUTION_TIME=60

## --- SCRIPTS ---
#COPY upgrade.sh /upgrade.sh
#COPY restore.sh /restore.sh
#COPY backup.sh /backup.sh

## --- CACTI ---
COPY container-files /

RUN \
    chmod +x /upgrade.sh && \
    chmod +x /restore.sh && \
    chmod +x /backup.sh  && \
    mkdir /backups && \
    \
    echo "-------------------------------------------" && \
    echo "yum - install & update all needed packages." && \
    echo "-------------------------------------------" && \
    rpm -Uvh \
        https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm --rebuilddb && yum clean all && \
    yum install yum-utils && \
    yum-config-manager --enable remi-php74 && \
    yum update -y && \
    yum install -y \
        rrdtool net-snmp net-snmp-utils cronie php-ldap php-devel mysql php \
        ntp bison php-cli php-mysql php-common php-mbstring php-snmp curl \
        php-gd openssl openldap mod_ssl php-pear net-snmp-libs php-pdo php-gmp \
        autoconf automake gcc gzip help2man libtool make net-snmp-devel \
        m4 libmysqlclient-devel libmysqlclient openssl-devel dos2unix wget \
        sendmail mariadb-devel which python-pip && \
    yum clean all && \
    \
    echo "----------------------------------------------" && \
    echo "python - install & update all needed packages." && \
    echo "----------------------------------------------" && \
    pip install simplejson && \
    \
    echo "----------------------------------------------------------" && \
    echo "Download, extracting and installing Cacti files to /cacti." && \
    echo "----------------------------------------------------------" && \
    curl -L -o /tmp/cacti-${CACTI_VERSION}.tgz https://github.com/Cacti/cacti/archive/release/${CACTI_VERSION}.tar.gz && \
    mkdir -p /cacti && \
    tar zxvf /tmp/cacti-${CACTI_VERSION}.tgz -C /cacti --strip-components=1 && \
    rm -f /tmp/cacti-${CACTI_VERSION}.tgz && \
    \
    echo "----------------------------------------------------------" && \
    echo "Download, extracting and installing Spine files to /spine." && \
    echo "----------------------------------------------------------" && \
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
    echo "------------------------------------------------------------------------" && \
    echo "Fix cron issues - https://github.com/CentOS/CentOS-Dockerfiles/issues/31" && \
    echo "------------------------------------------------------------------------" && \
    sed -i '/session required pam_loginuid.so/d' /etc/pam.d/crond && \
    \
    echo "----------" && \
    echo "misc setup" && \
    echo "----------" && \
    echo "ServerName localhost" > /etc/httpd/conf.d/fqdn.conf

## --- SERVICE CONFIGS ---
#COPY configs /template_configs

## --- SETTINGS/EXTRAS ---
#COPY plugins /cacti_install/plugins
#COPY templates /templates
#COPY settings /settings

## --- Start ---
#COPY start.sh /start.sh
CMD ["/start.sh"]

EXPOSE 80 443
