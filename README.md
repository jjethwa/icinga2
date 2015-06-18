# icinga2

This repository contains the source for the
[icinga2](https://www.icinga.org/icinga2/) [docker](https://www.docker.com)
image.

## Image details

1. Based on debian:latest
1. Supervisor, Apache2, MySQL, icinga2, icinga-web, and icingaweb2
1. No SSH.  Use [nsenter](https://github.com/jpetazzo/nsenter)
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

Icinga Web 2 can be accessed at http://localhost/icingaweb2 with the credentials icingaadmin:icinga  Please remember that Icinga Web 2 is still a release candidate so configurations, etc might change

## Environment variables & Volumes

```
ICINGA_PASSWORD
ICINGA_WEB_PASSWORD
ICINGAWEB2_PASSWORD
IDO_PASSWORD
DEBIAN_SYS_MAINT_PASSWORD
```

```
/etc/icinga2
/etc/icinga-web
/etc/icingaweb2
/var/lib/mysql
/var/lib/icinga2
```
