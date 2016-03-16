# icinga2

This repository contains the source for the
[icinga2](https://www.icinga.org/icinga2/) [docker](https://www.docker.com)
image.

## Image details

1. Based on debian:jessie
1. Supervisor, Apache2, MySQL, icinga2, icinga-web, icingacli, and icingaweb2
1. No SSH.  Use docker [exec](https://docs.docker.com/engine/reference/commandline/exec/) or [nsenter](https://github.com/jpetazzo/nsenter)
1. If no passwords are not supplied, they will be randomly generated and shown via stdout.

## Automated build

    docker pull jordan/icinga2

## Usage

Start a new container and bind to host's port 80

    sudo docker run -p 80:80 -t jordan/icinga2:latest

Start a new container and supply the icinga and icinga_web password

    sudo docker run -e ICINGA_PASSWORD="icinga" -e ICINGA_WEB_PASSWORD="icinga_web" -t jordan/icinga2:latest

The Icinga Web interface is accessible at http://localhost/icinga-web with the credentials root:password

## Icinga Web 2

Icinga Web 2 can be accessed at http://localhost/icingaweb2 with the credentials icingaadmin:icinga

## Graphite

The graphite writer can be enabled by setting the ICINGA2_FEATURE_GRAPHITE variable to true or 1 and also supplying values for ICINGA2_FEATURE_GRAPHITE_HOST and ICINGA2_FEATURE_GRAPHITE_PORT.  This container does not have graphite  and the carbon daemons installed so ICINGA2_FEATURE_GRAPHITE_HOST should not be set to localhost.

Example:

```
sudo docker run -e --link graphite:graphite -e ICINGA2_FEATURE_GRAPHITE=true -e ICINGA2_FEATURE_GRAPHITE_HOST=graphite -e ICINGA2_FEATURE_GRAPHITE_PORT=2003 -t jordan/icinga2:latest
```

## Environment variables & Volumes

```
ICINGA_PASSWORD - MySQL password for icinga
ICINGA_WEB_PASSWORD - MySQL password for icinga_web
ICINGAWEB2_PASSWORD - MySQL password for icingaweb2
IDO_PASSWORD - MySQL password for ido
DEBIAN_SYS_MAINT_PASSWORD
ICINGA2_FEATURE_GRAPHITE - false (default).  Set to true or 1 to enable graphite writer
ICINGA2_FEATURE_GRAPHITE_HOST - graphite (default).  Set to link name, hostname, or IP address where Carbon daemon is running
ICINGA2_FEATURE_GRAPHITE_PORT - 2003 (default).  Carbon port

```

```
/etc/icinga2
/etc/icinga-web
/etc/icingaweb2
/var/lib/mysql
/var/lib/icinga2
```
