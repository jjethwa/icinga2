FROM debian:latest
MAINTAINER Jordan Jethwa

# Environment variables
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get -qqy upgrade && apt-get -qqy install --no-install-recommends sudo procps ca-certificates wget supervisor mysql-server mysql-client apache2
RUN mkdir -p /opt/supervisor
ADD mysql_supervisor /opt/supervisor/mysql_supervisor
ADD icinga2_supervisor /opt/supervisor/icinga2_supervisor
ADD apache2_supervisor /opt/supervisor/apache2_supervisor
RUN chmod u+x /opt/supervisor/mysql_supervisor /opt/supervisor/icinga2_supervisor /opt/supervisor/apache2_supervisor
ADD icinga2.conf /etc/supervisor/conf.d/icinga2.conf
RUN wget --quiet -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/debian icinga-wheezy main" >> /etc/apt/sources.list
RUN apt-get -qq update && apt-get -qqy install icinga2 icinga2-ido-mysql icinga-web && apt-get clean
ADD icinga2_init /tmp/icinga2_init
RUN chmod u+x /tmp/icinga2_init && /tmp/icinga2_init && rm /tmp/icinga2_init

EXPORT 80

# Start Supervisor
CMD ["/usr/bin/supervisord"]
