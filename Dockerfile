# Dockerfile for icinga2 with icingaweb2
# https://github.com/jjethwa/icinga2

FROM debian:jessie

MAINTAINER Jordan Jethwa

ENV DEBIAN_FRONTEND noninteractive
ENV ICINGA2_FEATURE_GRAPHITE false
ENV ICINGA2_FEATURE_GRAPHITE_HOST graphite
ENV ICINGA2_FEATURE_GRAPHITE_PORT 2003

ARG GITREF_ICINGAWEB2=master
ARG GITREF_DIRECTOR=master

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

RUN    mv /etc/icingaweb2/ /etc/icingaweb2.dist \
    && mkdir /etc/icingaweb2 \
    && mv /etc/icinga2/ /etc/icinga2.dist \
    && mkdir /etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && usermod -aG nagios www-data \
    && chmod u+s,g+s \
        /bin/ping \
        /bin/ping6 \
        /usr/lib/nagios/plugins/check_icmp

# Temporary hack to get icingaweb2 modules via git
RUN wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2/archive/${GITREF_ICINGAWEB2}.tar.gz" \
  | tar xz --strip-components=2 --directory=/etc/icingaweb2.dist/modules -f - icingaweb2-${GITREF_ICINGAWEB2}/modules/monitoring icingaweb2-${GITREF_ICINGAWEB2}/modules/doc

# Icinga Director
RUN wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-director/archive/${GITREF_DIRECTOR}.tar.gz" \
  | tar xz --strip-components=1 --directory=/etc/icingaweb2.dist/modules/director --exclude=.gitignore -f -

EXPOSE 80 443 5665

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
