# Dockerfile for icinga2 with icinga-web
# https://github.com/jjethwa/icinga2
# Icinga 2.3.5

FROM debian:wheezy

MAINTAINER Jordan Jethwa

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update \
    && apt-get -qqy upgrade \
    && apt-get -qqy install --no-install-recommends bash sudo procps ca-certificates wget supervisor mysql-server mysql-client apache2 pwgen unzip php5-ldap
RUN wget --quiet -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/debian icinga-wheezy-snapshots main" >> /etc/apt/sources.list
RUN apt-get -qq update \
    && apt-get -qqy install --no-install-recommends icinga2 icinga2-ido-mysql icinga-web nagios-plugins icingaweb2 \
    && apt-get clean

ADD content/ /

RUN chmod u+x /opt/supervisor/mysql_supervisor /opt/supervisor/icinga2_supervisor /opt/supervisor/apache2_supervisor
RUN chmod u+x /opt/run

# Temporary hack to get icingaweb2 modules via git
RUN mkdir -p /etc/icingaweb2/enabledModules
RUN wget --no-cookies --no-check-certificate "https://github.com/Icinga/icingaweb2/archive/master.zip" -O /tmp/icingaweb2.zip
RUN unzip /tmp/icingaweb2.zip "icingaweb2-master/modules/doc/*" "icingaweb2-master/modules/monitoring/*" -d "/tmp/icingaweb2"
RUN cp -R /tmp/icingaweb2/icingaweb2-master/modules/monitoring /etc/icingaweb2/modules/
RUN cp -R  /tmp/icingaweb2/icingaweb2-master/modules/doc /etc/icingaweb2/modules/
RUN rm -rf /tmp/icingaweb2.zip /tmp/icingaweb2

EXPOSE 80 443 5665

VOLUME  ["/etc/icinga2", "/etc/icinga-web", "/etc/icingaweb2", "/var/lib/mysql", "/var/lib/icinga2"]

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
