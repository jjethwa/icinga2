# Dockerfile for icinga2 with icinga-web
# https://github.com/jjethwa/icinga2
# Icinga 2.2.2

FROM debian:wheezy

MAINTAINER bram <bram-dockerfiles@grmbl.net>

# Environment variables
ENV DEBIAN_FRONTEND noninteractive

RUN echo 
RUN apt-get -qq update && apt-get -qqy upgrade && apt-get -qqy install --no-install-recommends bash sudo procps ca-certificates wget supervisor mysql-server mysql-client apache2 pwgen 
RUN mkdir -p /opt/supervisor
ADD mysql_supervisor /opt/supervisor/mysql_supervisor
ADD icinga2_supervisor /opt/supervisor/icinga2_supervisor
ADD apache2_supervisor /opt/supervisor/apache2_supervisor
RUN chmod u+x /opt/supervisor/mysql_supervisor /opt/supervisor/icinga2_supervisor /opt/supervisor/apache2_supervisor
ADD icinga2.conf /etc/supervisor/conf.d/icinga2.conf
RUN wget --quiet -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/debian icinga-wheezy-snapshots main" >> /etc/apt/sources.list
# Ubuntu
#RUN echo "deb http://ppa.launchpad.net/formorer/icinga/debian wheezy main" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0x4A132479423673E80ACCA85420EEDAFD36862847
RUN apt-get -qq update && apt-get -qqy install --no-install-recommends icinga2 icinga2-ido-mysql icinga-web nagios-plugins && apt-get clean
# fix innodb aio error
ADD innodb_override_aio.cnf /etc/mysql/conf.d/innodb_override_aio.cnf
ADD database-ido.xml /etc/icinga-web/conf.d/database-ido.xml
ADD run /opt/run
RUN chmod u+x /opt/run

EXPOSE 80 443

VOLUME  ["/etc/icinga2", "/etc/icinga-web", "/var/lib/mysql", "/etc/dbconfig-common" ]

# Initialize and run Supervisor
CMD ["/opt/run"]
