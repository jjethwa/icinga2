# Dockerfile for icinga2 with icinga-web
# https://github.com/jjethwa/icinga2
# Icinga 2.2.3

FROM debian:wheezy

MAINTAINER Jordan Jethwa

# Environment variables
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get -qqy upgrade && apt-get -qqy install --no-install-recommends bash sudo procps ca-certificates wget supervisor mysql-server mysql-client apache2 pwgen
RUN mkdir -p /opt/supervisor
ADD mysql_supervisor /opt/supervisor/mysql_supervisor
ADD icinga2_supervisor /opt/supervisor/icinga2_supervisor
ADD apache2_supervisor /opt/supervisor/apache2_supervisor
RUN chmod u+x /opt/supervisor/mysql_supervisor /opt/supervisor/icinga2_supervisor /opt/supervisor/apache2_supervisor
ADD icinga2.conf /etc/supervisor/conf.d/icinga2.conf
RUN wget --quiet -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/debian icinga-wheezy-snapshots main" >> /etc/apt/sources.list
RUN apt-get -qq update && apt-get -qqy install --no-install-recommends icinga2 icinga2-ido-mysql icinga-web nagios-plugins && apt-get clean
ADD database-ido.xml /etc/icinga-web/conf.d/database-ido.xml
ADD run /opt/run
RUN chmod u+x /opt/run

EXPOSE 80 443

VOLUME  ["/etc/icinga2", "/etc/icinga-web", "/var/lib/mysql"]

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
