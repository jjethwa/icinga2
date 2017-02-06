# Dockerfile for icinga2 with icingaweb2
# https://github.com/jjethwa/icinga2

FROM multiarch/debian-debootstrap:armhf-jessie

MAINTAINER Jordan Jethwa

ENV APACHE2_HTTP=REDIRECT \
    DEBIAN_FRONTEND=noninteractive \
    ICINGA2_FEATURE_GRAPHITE=false \
    ICINGA2_FEATURE_GRAPHITE_HOST=graphite \
    ICINGA2_FEATURE_GRAPHITE_PORT=2003 \
    ICINGA2_FEATURE_GRAPHITE_URL=http://${ICINGA2_FEATURE_GRAPHITE_HOST} \
    ICINGA2_USER_FULLNAME="Icinga2" \
    ICINGA2_FEATURE_DIRECTOR="true" \
    ICINGA2_FEATURE_DIRECTOR_KICKSTART="true" \
    ICINGA2_FEATURE_DIRECTOR_USER="icinga2-director"

ARG GITREF_ICINGAWEB2=master
ARG GITREF_DIRECTOR=master
ARG GITREF_MODGRAPHITE=master

RUN apt-get -qq update \
     && apt-get -qqy upgrade \
     && apt-get -qqy install --no-install-recommends \
          apache2 \
          ca-certificates \
          curl \
          mailutils \
          mysql-client \
          mysql-server \
          php5-curl \
          php5-ldap \
          php5-mysql \
          procps \
          pwgen \
          snmp \
          ssmtp \
          sudo \
          supervisor \
          unzip \
          wget \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

RUN wget --quiet -O - https://packages.icinga.org/icinga.key \
     | apt-key add - \
     && echo "deb http://packages.icinga.org/debian icinga-jessie main" > /etc/apt/sources.list.d/icinga2.list \
     && apt-get -qq update \
     && apt-get -qqy install --no-install-recommends \
          icinga2 \
          icinga2-ido-mysql \
          icingacli \
          icingaweb2 \
          monitoring-plugins \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

ADD content/ /

# Temporary hack to get icingaweb2 modules via git
RUN mkdir -p /usr/local/share/icingaweb2/modules/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2/archive/${GITREF_ICINGAWEB2}.tar.gz" \
    | tar xz --strip-components=2 --directory=/usr/local/share/icingaweb2/modules -f - icingaweb2-${GITREF_ICINGAWEB2}/modules/monitoring icingaweb2-${GITREF_ICINGAWEB2}/modules/doc \
# Icinga Director
    && mkdir -p /usr/local/share/icingaweb2/modules/director/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-director/archive/${GITREF_DIRECTOR}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/director --exclude=.gitignore -f - \
    && icingacli module enable director \
# Icingaweb2 Graphite
    && mkdir -p /usr/local/share/icingaweb2/modules/graphite \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-graphite/archive/${GITREF_ICINGAWEB2}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/graphite -f - icingaweb2-module-graphite-${GITREF_MODGRAPHITE}/ \
    && cp -r /usr/local/share/icingaweb2/modules/graphite/sample-config/icinga2/ /etc/icingaweb2/modules/graphite \
# Final fixes
    && mv /etc/icingaweb2/ /etc/icingaweb2.dist \
    && mkdir /etc/icingaweb2 \
    && mv /etc/icinga2/ /etc/icinga2.dist \
    && mkdir /etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && usermod -aG nagios www-data \
    && chmod u+s,g+s \
        /bin/ping \
        /bin/ping6 \
        /usr/lib/nagios/plugins/check_icmp

EXPOSE 80 443 5665

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
