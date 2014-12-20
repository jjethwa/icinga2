icinga2
==============

This repository contains the source for the [icinga2](https://www.icinga.org/icinga2/) [docker](https://docker.io) image.

# Image details

1. Based on debian:latest
1. Supervisor, Apache2, MySQL, icinga2, and icinga-web 
1. No SSH.  Use [nsenter](https://github.com/jpetazzo/nsenter)
1. If no passwords are not supplied, they will be randomly generated and shown via stdout.

# Automated build

```docker pull jordan/icinga2```

# Usage
Start a new container and bind to host's port 80

```sudo docker run -p 80:80 -t jordan/icinga2:latest```

Start a new container and supply the icinga and icinga_web password

```sudo docker run -e ICINGA_PASSWORD="icinga" -e ICINGA_WEB_PASSWORD="icinga_web" -t jordan/icinga2:latest```

# Environment variables & Volumes

```
ICINGA_PASSWORD
ICINGA_WEB_PASSWORD
IDO_PASSWORD
DEBIAN_SYS_MAINT_PASSWORD
```

```
/etc/icinga2
/etc/icinga-web
/var/lib/mysql
```

# Issues

mysql errors:
 The number of files is too low (65k) and should be increased.
 We might have to run in privileged mode for this and/or add a flag for more (fs.aio-max-nr = 1048576)

