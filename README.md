# Docker MySQL 8 Client

[![devel](https://github.com/joseluisq/docker-mysql-client/actions/workflows/devel.yml/badge.svg)](https://github.com/joseluisq/docker-mysql-client/actions/workflows/devel.yml) ![Docker Image Size](https://img.shields.io/docker/image-size/joseluisq/mysql-client/8) ![Docker Image Version](https://img.shields.io/docker/v/joseluisq/mysql-client/8) ![Docker Pulls](https://img.shields.io/docker/pulls/joseluisq/mysql-client.svg)

> [MySQL 8 client](https://dev.mysql.com/doc/r**Note:** efman/8.0/en/programs-client.html) for export and import databases easily using Docker.

This is a __Linux Docker image__ using latest __Debian [11-slim](https://hub.docker.com/_/debian?tab=tags&page=1&name=11-slim)__ ([Bullseye](https://www.debian.org/News/2021/20210814)).

*__Note:__ If you are looking for a __MariaDB Client__ then go to [Alpine MySQL Client](https://github.com/joseluisq/alpine-mysql-client) project.*

🐳  View on [Docker Hub](https://hub.docker.com/r/joseluisq/mysql-client/)

## MySQL 8 Client programs

```sh
mysql
mysql_find_rows
mysql_waitpid
mysqladmin
mysqldump
mysqlimport
mysql-export
mysql_fix_extensions
mysqlaccess
mysqlcheck
mysqldumpslow
mysqlshow
```

For more details see official [MySQL 8 Client Programs](https://dev.mysql.com/doc/refman/8.0/en/programs-client.html) documentation.

## Usage

```sh
docker run -it --rm joseluisq/mysql-client mysql --version
# mysql  Ver 8.0.28 for Linux on x86_64 (MySQL Community Server - GPL)
```

## User privileges

- Default user (unprivileged) is `mysql`.
- `mysql` home directory is located at `/home/mysql`.
- If you want a full privileged user try `root`. E.g append a `--user root` argument to `docker run`.

## Exporter

`mysql_exporter` is a custom tool which exports a database script using `mysqldump`. Additionally it support gzip compression.
It can be configured via environment variables or using `.env` file.

### Setup via environment variables

```env
# Connection settings (optional)
DB_PROTOCOL=tcp
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DEFAULT_CHARACTER_SET=utf8

# GZip export file (optional)
DB_EXPORT_GZIP=false

# SQL or Gzip export file (optional).
# If `DB_IMPORT_GZIP` is `true` then file name should be `database_name.sql.gz`
DB_EXPORT_FILE_PATH=database_name.sql

# Database settings (required)
DB_NAME=""
DB_USERNAME=""
DB_PASSWORD=""

# Additional arguments (optional)
DB_ARGS=
```

**Notes:**

- `DB_EXPORT_GZIP=true`: Compress the sql file using Gzip (optional). If `false` or not defined then the exported file will be a `.sql` file.
- `DB_ARGS`: can be used in order to pass more `mysqldump` arguments (optional). 
- An `.env` example file can be found at [./8.0/env/mysql_exporter.env](./8.0/env/mysql_exporter.env)

### Export a database using a Docker container

The following Docker commands create a container in order to export a database and then remove such container automatically.

Note that `mysql_exporter` supports environment variables or a `.env` file can be passed as an argument.

```sh
docker run --rm -it \
    --volume $PWD:/home/mysql/sample \
    --user $(id -u $USER):$(id -g $USER) \
    --workdir /home/mysql/sample \
        joseluisq/mysql-client:8 \
        mysql_exporter production.env

# MySQL 8 Client - Exporter
# =========================
# mysqldump  Ver 8.0.28 for Linux on x86_64 (MySQL Community Server - GPL)

# Exporting database `mydb` into a SQL script file...
# Output file: database_name.sql (SQL Text)
# mysqldump: [Warning] Using a password on the command line interface can be insecure.
# Database `mydb` was exported on 0s successfully!
# File exported: database_name.sql (4.0K / SQL Text)
```

__Notes:__

- `--volume $PWD:/home/mysql/sample` specificy a [bind mount directory](https://docs.docker.com/storage/bind-mounts/) from host to container.
- `$PWD` is just a example host working directory. Use your own path.
- `/home/mysql/` is default home directory user (optional). View [User privileges](#user-privileges) section above.
- `/home/mysql/sample` is a container directory that Docker will create for us.
- `--workdir /home/mysql/sample` specificy the working directory used by default inside the container.
- `production.env` is a custom env file path with the corresponding environment variables passed as argument. That file shoud available in your host working directory. E.g `$PWD` in my case.

### Export a database using a Docker Compose file

```yaml
version: "3.3"

services:
  exporter:
    image: joseluisq/mysql-client:8
    env_file: .env
    command: mysql_exporter
    working_dir: /home/mysql/sample
    volumes:
      - ./:/home/mysql/sample
    networks:
      - default
```

## Importer

`mysql_importer` is a custom tool which imports a SQL script file (text or Gzip) using `mysql` command.
It can be configured via environment variables or using `.env` file.

### Setup via environment variables

```env
# Connection settings (optional)
DB_PROTOCOL=tcp
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DEFAULT_CHARACTER_SET=utf8

# GZip import support (optional)
DB_IMPORT_GZIP=false

# SQL or Gzip import file (required)
# If `DB_IMPORT_GZIP` is `true` then file name should be `database_name.sql.gz`
DB_IMPORT_FILE_PATH=database_name.sql

# Database settings (required)
DB_NAME=""
DB_USERNAME=""
DB_PASSWORD=""

# Additional arguments (optional)
DB_ARGS=
```

### Import a SQL script via a Docker container

The following Docker commands create a container in order to import a SQL script file to an specific database and removing the container afterwards.

Note that `mysql_importer` supports environment variables or a `.env` file can be passed as an argument.

```sh
docker run --rm -it \
    --volume $PWD:/home/mysql/sample \
    --user $(id -u $USER):$(id -g $USER) \
    --workdir /home/mysql/sample \
        joseluisq/mysql-client:8 \
        mysql_importer production.env

# MySQL 8 Client - Importer
# =========================
# mysql  Ver 8.0.28 for Linux on x86_64 (MySQL Community Server - GPL)

# Importing a SQL script file into database `mydb`...
# Input file: database_name.sql (4.0K / SQL Text)
# mysql: [Warning] Using a password on the command line interface can be insecure.
# Database `mydb` was imported on 1s successfully!
```

**Notes:**

- `DB_IMPORT_GZIP=true`: Decompress a dump file using Gzip (optional). If `false` or not defined then the import file will be treated as plain `.sql` file.
- `DB_ARGS`: can be used in order to pass more `mysql` arguments (optional). 
- An `.env` example file can be found at [./8.0/env/mysql_importer.env](./8.0/env/mysql_importer.env)

## Contributions

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in current work by you, as defined in the Apache-2.0 license, shall be dual licensed as described below, without any additional terms or conditions.

Feel free to send some [pull request](https://github.com/joseluisq/docker-mysql-client/pulls) or file some [issue](https://github.com/joseluisq/docker-mysql-client/issues).

## License

This work is primarily distributed under the terms of both the [MIT license](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE).

© 2022-present [Jose Quintana](https://git.io/joseluisq)
