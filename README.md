# icinga2

This repository contains the source for the [icinga2](https://www.icinga.org/icinga2/) [docker](https://www.docker.com) image.

The dockerhub-repository is located at [https://hub.docker.com/r/jordan/icinga2/](https://hub.docker.com/r/jordan/icinga2/).

This build is automated by push for the git-repo. Just crawl it via:

    docker pull jordan/icinga2

## Image details

1. Based on debian:stretch
1. Key-Features:
   - icinga2
   - icingacli
   - icingaweb2
   - icingaweb2-director module
   - icingaweb2-graphite module
   - icingaweb2-module-aws
   - ssmtp
   - MySQL
   - Supervisor
   - Apache2
   - SSL Support
1. No SSH. Use docker [exec](https://docs.docker.com/engine/reference/commandline/exec/) or [nsenter](https://github.com/jpetazzo/nsenter)
1. If passwords are not supplied, they will be randomly generated and shown via stdout.

## Usage

Start a new container and bind to host's port 80

    docker run -p 80:80 -h icinga2 -t jordan/icinga2:latest

### docker-compose

Download the [`docker-compose.yml`](./docker-compose.yml) file and create a file `secrets_sql.env`, which contains the `MYSQL_ROOT_PASSWORD` variable.

    curl -O https://raw.githubusercontent.com/jjethwa/icinga2/master/docker-compose.yml
    echo "MYSQL_ROOT_PASSWORD=<password>" > secrets_sql.env
    docker-compose up

This boots up an icinga(web)2 container with another MySQL container reachable on [http://localhost](http://localhost) with the default credentials *icingaadmin*:*icinga*.

## Icinga Web 2

Icinga Web 2 can be accessed at [http://localhost/icingaweb2](http://localhost/icingaweb2) with the credentials *icingaadmin*:*icinga* (if not set differently via variables).  When using a volume for /etc/icingaweb2, make sure to set ICINGAWEB2_ADMIN_USER and ICINGAWEB2_ADMIN_PASS

### Saving PHP Sessions

If you want to save your php-sessions over multiple boots, mount `/var/lib/php/sessions/` into your container. Session files will get saved there.

example:
```
docker run [...] -v $PWD/icingaweb2-sessions:/var/lib/php/sessions/ jordan/icinga2
```

## Graphite

The graphite writer can be enabled by setting the `ICINGA2_FEATURE_GRAPHITE` variable to `true` or `1` and also supplying values for `ICINGA2_FEATURE_GRAPHITE_HOST` and `ICINGA2_FEATURE_GRAPHITE_PORT`. This container does not have graphite and the carbon daemons installed so `ICINGA2_FEATURE_GRAPHITE_HOST` should not be set to `localhost`.

Example:

```
docker run -t \
  --link graphite:graphite \
  -e ICINGA2_FEATURE_GRAPHITE=true \
  -e ICINGA2_FEATURE_GRAPHITE_HOST=graphite \
  -e ICINGA2_FEATURE_GRAPHITE_PORT=2003 \
  jordan/icinga2:latest
```

## Icinga Director

The [Icinga Director](https://github.com/Icinga/icingaweb2-module-director) Icinga Web 2 module is installed and enabled by default. You can disable the automatic kickstart when the container starts by setting the `DIRECTOR_KICKSTART` variable to false. To customize the kickstart settings, modify the `/etc/icingaweb2/modules/director/kickstart.ini`.

## API Master

The container gets automatically configured as an API master. But it has some caveats. Please make sure:

- Set the container's hostname (`-h` or `hostname`)
  - The hostname has to match the name, your sattelites are configured to access the master.
- Forward the `5665` port
- Mount **both** volumes: `/etc/icinga2`, `/var/lib/icinga2`

## Sending Notification Mails

The container has `ssmtp` installed, which forwards mails to a preconfigured static server.

You have to create the files `ssmtp.conf` for general configuration and `revaliases` (mapping from local Unix-user to mail-address).

```
# ssmtp.conf
root=<E-Mail address to use on>
mailhub=smtp.<YOUR_MAILBOX>:587
UseSTARTTLS=YES
AuthUser=<Username for authentication (mostly the complete e-Mail-address)>
AuthPass=<YOUR_PASSWORD>
FromLineOverride=NO
```
**But be careful, ssmtp is not able to process special chars within the password correctly!**

`revaliases` follows the format: `Unix-user:e-Mail-address:server`.
Therefore the e-Mail-address has to match the `root`'s value in `ssmtp.conf`
Also server has to match mailhub from `ssmtp.conf` **but without the port**.

```
# revaliases
root:<VALUE_FROM_ROOT>:smtp.<YOUR_MAILBOX>
nagios:<VALUE_FROM_ROOT>:smtp.<YOUR_MAILBOX>
www-data:<VALUE_FROM_ROOT>:smtp.<YOUR_MAILBOX>
```

These files have to get mounted into the container. Add these flags to your `docker run`-command:
```
-v $(pwd)/revaliases:/etc/ssmtp/revaliases:ro
-v $(pwd)/ssmtp.conf:/etc/ssmtp/ssmtp.conf:ro
```

If you want to change the display-name of sender-address, you have to define the variable `ICINGA2_USER_FULLNAME`.

If this does not work, please ask your provider for the correct mail-settings or consider the [ssmtp.conf(5)-manpage](https://manpages.debian.org/stretch/ssmtp/ssmtp.conf.5.en.html) or Section ["Reverse Aliases" on ssmtp(8)](https://manpages.debian.org/stretch/ssmtp/ssmtp.8.en.html#REVERSE_ALIASES).
Also you can debug your config, by executing inside your container `ssmtp -v $address` and pressing 2x Enter.
It will send an e-Mail to `$address` and give verbose log and all error-messages.

## SSL Support

For enabling of SSL support, just add a volume to `/etc/apache2/ssl`, which contains these files:

- `icinga2.crt`: The certificate file for apache
- `icinga2.key`: The corresponding private key
- `icinga2.chain` (optional): If a certificate chain is needed, add this file. Consult your CA-vendor for additional info.

For https-redirection or http/https dualstack consult `APACHE2_HTTP` env-variable.

# Adding own modules

To use your own modules, you're able to install these into `enabledModules`-folder of your `/etc/icingaweb2` volume.

# MySQL connections

The container has support to run a MySQL server inside or access some external resources. By default, the MySQL server inside the container is setup, but when using the `docker-compose.yml` project, the server is located inside an extra container. Future releases will have this as the default and require an external MySQL/MariaDB container.

If you use the image plain or the `docker-compose.yml` project, you don't have to worry about anything for MySQL. Only, if you want to split the container from the MySQL server, it's necessary to give some variables.

## External MySQL servers

If you have the image running plain or use the `docker-compose.yml` project, there is no necessity to fool around with these variables.

To connect the container with the MySQL server, you have fine granular control via environment variables. For every necessary database, there is a set of variables, which describe the connection to it. In theory, the databases could get distributed over multiple hosts.

All variables are a combination of the service and the property with the format `<SERVICE>_MYSQL_<PROPERTY>`, while

- `<SERVICE>` can be one of `ICINGA2_IDO`, `ICINGAWEB2`, `ICINGAWEB2_DIRECTOR`
- `<PROPERTY>` can be one of `HOST`, `PORT`, `DATA`, `USER`, `PASS`

The variables default their respective `DEFAULT` service variable.

- `DEFAULT_MYSQL_HOST`: The server hostname (defaults to `localhost`)
- `DEFAULT_MYSQL_PORT`: The server port (defaults to `3306`)
- `DEFAULT_MYSQL_DATA`: The database (defaults to *unset*, the specific services have separate DBs)
	- `ICINGA2_IDO_MYSQL_DATA`: The database for icinga2 IDO (defaults to `icinga2idomysql`)
	- `ICINGAWEB2_MYSQL_DATA`: The database for icingaweb2 (defaults to `icingaweb2`)
	- `ICINGAWEB2_DIRECTOR_MYSQL_DATA`: The database for icingaweb2 director (defaults to `icingaweb2_director`)
- `DEFAULT_MYSQL_USER`: The MySQL user to access the database (defaults to `icinga2`)
- `DEFAULT_MYSQL_PASS`: The password for the MySQL user. (defaults to *randomly generated string*)

## Moving to separate MySQL-container

1. Start your current container as always.
1. Run `docker exec <container> i2-port-mysqldb`
1. Shutdown the container
1. Copy the MySQL datafolder from the `icinga2` container to your new `mariadb` container.
1. Change the environment variable `DEFAULT_MYSQL_HOST` to point to your new MySQL container.
1. Add the environment variable `MYSQL_ROOT_PASSWORD` to the icinga2 container, with the value of your password you currently set.
1. Start your container**s**.

# Reference

## Environment variables Reference

| Environmental Variable | Default Value | Description |
| ---------------------- | ------------- | ----------- |
| `ICINGA2_FEATURE_GRAPHITE` | false | Set to true or 1 to enable graphite writer |
| `ICINGA2_FEATURE_GRAPHITE_HOST` | graphite | hostname or IP address where Carbon/Graphite daemon is running |
| `ICINGA2_FEATURE_GRAPHITE_PORT` | 2003 | Carbon port for graphite |
| `ICINGA2_FEATURE_GRAPHITE_URL` | http://${ICINGA2_FEATURE_GRAPHITE_HOST} | Web-URL for Graphite |
| `ICINGA2_FEATURE_GRAPHITE_SEND_THRESHOLD` | true | If you want to send `min`, `max`, `warn` and `crit` values for perf data |
| `ICINGA2_FEATURE_GRAPHITE_SEND_METADATA` | false | If you want to send `state`, `latency` and `execution_time` values for the checks |
| `ICINGA2_FEATURE_DIRECTOR` | true | Set to false or 0 to disable icingaweb2 director |
| `ICINGA2_FEATURE_DIRECTOR_USER` | icinga2-director | Icinga2director Login User |
| `ICINGA2_FEATURE_DIRECTOR_PASS` | *random generated each start* | Icinga2director Login Password<br>*Set this to prevent continues [admin] modify apiuser "icinga2-director" activities* |
| `DIRECTOR_KICKSTART` | true | Set to false to disable icingaweb2 director's auto kickstart at container startup. *Value is only used, if icingaweb2 director is enabled.* |
| `ICINGAWEB2_ADMIN_USER` | icingaadmin | Icingaweb2 Login User<br>*After changing the username, you should also remove the old User in icingaweb2-> Configuration-> Authentication-> Users* |
| `ICINGAWEB2_ADMIN_PASS` | icinga | Icingaweb2 Login Password |
| `ICINGA2_USER_FULLNAME` | Icinga | Sender's display-name for notification e-Mails |
| `APACHE2_HTTP` | `REDIRECT` | **Variable is only active, if both SSL-certificate and SSL-key are in place.** `BOTH`: Allow HTTP and https connections simultaneously. `REDIRECT`: Rewrite HTTP-requests to HTTPS |
| `MYSQL_ROOT_PASSWORD` | *unset* | If your MySQL host is not on `localhost`, but you want the icinga2 container to setup the DBs for itself, specify the root password of your MySQL server in this variable. |
| *other MySQL variables* | *none* | All combinations of MySQL variables aren't listed in this reference. Please see above in the MySQL section for this. |

## Volume Reference

All these folders are configured and able to get mounted as volume. The bottom ones are not quite necessary.

| Volume | ro/rw | Description & Usage |
| ------ | ----- | ------------------- |
| /etc/apache2/ssl | **ro** | Mount optional SSL-Certificates (see SSL Support) |
| /etc/locale.gen | **ro** | In format of the well known locale.gen file. All locales listed in this file will get generated. |
| /etc/ssmtp/revaliases | **ro** | revaliases map (see Sending Notification Mails) |
| /etc/ssmtp/ssmtp.conf | **ro** | ssmtp configuration (see Sending Notification Mails) |
| /etc/icinga2 | rw | Icinga2 configuration folder |
| /etc/icingaweb2 | rw | Icingaweb2 configuration folder |
| /var/lib/mysql | rw | MySQL Database |
| /var/lib/icinga2 | rw | Icinga2 Data |
| /var/lib/php/sessions/ | rw | Icingaweb2 PHP Session Files |
| /var/log/apache2 | rw | logfolder for apache2 (not neccessary) |
| /var/log/icinga2 | rw | logfolder for icinga2 (not neccessary) |
| /var/log/icingaweb2 | rw | logfolder for icingaweb2 (not neccessary) |
| /var/log/mysql | rw | logfolder for mysql (not neccessary) |
| /var/log/supervisor | rw | logfolder for supervisord (not neccessary) |
| /var/spool/icinga2 | rw | spool-folder for icinga2 (not neccessary) |
| /var/cache/icinga2 | rw | cache-folder for icinga2 (not neccessary) |
