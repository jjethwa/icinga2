# Dockerfile for icinga2 with icinga-web
# https://github.com/jjethwa/icinga2
# Icinga 2.3.2

FROM debian:wheezy

MAINTAINER Jordan Jethwa

ENV DEBIAN_FRONTEND noninteractive

ADD content/ /

RUN apt-get -qq update \
    && apt-get -qqy upgrade \
    && apt-get -qqy install --no-install-recommends bash sudo procps ca-certificates wget supervisor mysql-server mysql-client apache2 pwgen
RUN mkdir -p /opt/supervisor
RUN chmod u+x /opt/supervisor/mysql_supervisor /opt/supervisor/icinga2_supervisor /opt/supervisor/apache2_supervisor
RUN wget --quiet -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/debian icinga-wheezy-snapshots main" >> /etc/apt/sources.list
RUN apt-get -qq update \
    && apt-get -qqy install --no-install-recommends icinga2 icinga2-ido-mysql icinga-web nagios-plugins \
    && apt-get clean
RUN chmod u+x /opt/run

EXPOSE 80 443

VOLUME  ["/etc/icinga2", "/etc/icinga-web", "/var/lib/mysql", "/var/lib/icinga2"]

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
