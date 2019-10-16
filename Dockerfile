# Dockerfile for icinga2 with icingaweb2
# https://github.com/jjethwa/icinga2

FROM debian:buster

ENV APACHE2_HTTP=REDIRECT \
    ICINGA2_FEATURE_GRAPHITE=false \
    ICINGA2_FEATURE_GRAPHITE_HOST=graphite \
    ICINGA2_FEATURE_GRAPHITE_PORT=2003 \
    ICINGA2_FEATURE_GRAPHITE_URL=http://graphite \
    ICINGA2_FEATURE_GRAPHITE_SEND_THRESHOLDS="true" \
    ICINGA2_FEATURE_GRAPHITE_SEND_METADATA="false" \
    ICINGA2_USER_FULLNAME="Icinga2" \
    ICINGA2_FEATURE_DIRECTOR="true" \
    ICINGA2_FEATURE_DIRECTOR_KICKSTART="true" \
    ICINGA2_FEATURE_DIRECTOR_USER="icinga2-director" \
    MYSQL_ROOT_USER=root

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    curl \
    dnsutils \
    file \
    gnupg \
    libdbd-mysql-perl \
    libdigest-hmac-perl \
    libnet-snmp-perl \
    locales \
    lsb-release \
    mailutils \
    mariadb-client \
    mariadb-server \
    netbase \
    openssh-client \
    openssl \
    php-curl \
    php-ldap \
    php-mysql \
    php-mbstring \
    procps \
    pwgen \
    snmp \
    msmtp \
    sudo \
    supervisor \
    unzip \
    wget \
    && apt-get --purge remove exim4 exim4-base exim4-config exim4-daemon-light \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN export DEBIAN_FRONTEND=noninteractive \
    && curl -s https://packages.icinga.com/icinga.key \
    | apt-key add - \
    && echo "deb http://packages.icinga.org/debian icinga-$(lsb_release -cs) main" > /etc/apt/sources.list.d/icinga2.list \
    && echo "deb http://deb.debian.org/debian $(lsb_release -cs)-backports main" > /etc/apt/sources.list.d/$(lsb_release -cs)-backports.list \
    && apt-get update \
    && apt-get install -y --install-recommends \
    icinga2 \
    icinga2-ido-mysql \
    icingacli \
    icingaweb2 \
    icingaweb2-module-doc \
    icingaweb2-module-monitoring \
    monitoring-plugins \
    nagios-nrpe-plugin \
    nagios-plugins-contrib \
    nagios-snmp-plugins \
    libmonitoring-plugin-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG GITREF_MODGRAPHITE=master
ARG GITREF_MODAWS=master
ARG GITREF_REACTBUNDLE=v0.7.0
ARG GITREF_INCUBATOR=v0.5.0
ARG GITREF_IPL=v0.3.0

RUN mkdir -p /usr/local/share/icingaweb2/modules/ \
    # Icinga Director
    && mkdir -p /usr/local/share/icingaweb2/modules/director/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-director/archive/v1.7.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/director --exclude=.gitignore -f - \
    # fix for https://github.com/Icinga/icingaweb2-module-director/issues/1993
    && sed -i 's/change_time TIMESTAMP NOT NULL,/change_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,/' \
    /usr/local/share/icingaweb2/modules/director/schema/mysql.sql \
    # Icingaweb2 Graphite
    && mkdir -p /usr/local/share/icingaweb2/modules/graphite \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-graphite/archive/v1.1.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/graphite -f - \
    # Icingaweb2 AWS
    && mkdir -p /usr/local/share/icingaweb2/modules/aws \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-aws/archive/v1.0.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/aws -f - \
    && wget -q --no-cookies "https://github.com/aws/aws-sdk-php/releases/download/2.8.30/aws.zip" \
    && unzip -d /usr/local/share/icingaweb2/modules/aws/library/vendor/aws aws.zip \
    && rm aws.zip \
    # Module Reactbundle
    && mkdir -p /usr/local/share/icingaweb2/modules/reactbundle/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-reactbundle/archive/v0.7.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/reactbundle -f - \
    # Module Incubator
    && mkdir -p /usr/local/share/icingaweb2/modules/incubator/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-incubator/archive/v0.5.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/incubator -f - \
    # Module Ipl
    && mkdir -p /usr/local/share/icingaweb2/modules/ipl/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-ipl/archive/v0.3.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/ipl -f - \
    && true

ADD content/ /

# Final fixes
RUN true \
    && sed -i 's/vars\.os.*/vars.os = "Docker"/' /etc/icinga2/conf.d/hosts.conf \
    && mv /etc/icingaweb2/ /etc/icingaweb2.dist \
    && mv /etc/icinga2/ /etc/icinga2.dist \
    && mkdir -p /etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && usermod -aG nagios www-data \
    && mkdir -p /var/log/icinga2 \
    && chmod 755 /var/log/icinga2 \
    && chown nagios:adm /var/log/icinga2 \
    && rm -rf \
    /var/lib/mysql/* \
    && chmod u+s,g+s \
    /bin/ping \
    /bin/ping6 \
    /usr/lib/nagios/plugins/check_icmp

EXPOSE 80 443 5665

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
