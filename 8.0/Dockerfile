# NOTE: Most of the file is borrowed from https://github.com/docker-library/mysql/blob/master/8.0/Dockerfile.debian

FROM debian:11.6-slim

ARG VERSION=0.0.0
ENV VERSION=${VERSION}

LABEL version="${VERSION}" \
    description="MySQL 8 client for export and import databases easily using Docker." \
    maintainer="Jose Quintana <joseluisq.net>"

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux \
    && groupadd -r mysql && useradd -r -g mysql mysql \
    && true

RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
        dirmngr \
        gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && true

# add gosu for easy step-down from root
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.16

RUN set -eux \
    && savedAptMark="$(apt-mark showmanual)" \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && apt-mark auto '.*' > /dev/null \
    && [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && chmod +x /usr/local/bin/gosu \
    && gosu --version \
    && gosu nobody true \
    && true

RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends \
        openssl \
# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
        perl \
        xz-utils \
        zstd \
    && rm -rf /var/lib/apt/lists/* \
    && true

RUN set -eux \
# gpg: key 3A79BD29: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
    && key='859BE8D7C586F538430B19C2467B942D3A79BD29' \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" \
    && mkdir -p /etc/apt/keyrings \
    && gpg --batch --export "$key" > /etc/apt/keyrings/mysql.gpg \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && true

ENV MYSQL_MAJOR 8.0
ENV MYSQL_VERSION 8.0.32-1debian11

# https://repo.mysql.com/apt/debian/pool/mysql-8.0/m/mysql-community/mysql-client_8.0.32-1debian11_amd64.deb
RUN set -eux \
    && echo 'deb [ signed-by=/etc/apt/keyrings/mysql.gpg ] http://repo.mysql.com/apt/debian/ bullseye mysql-8.0' > /etc/apt/sources.list.d/mysql.list \
    && true

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends \
        mysql-community-client="${MYSQL_VERSION}" \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql \
    && mkdir -p /var/lib/mysql \
    && chown -R mysql:mysql /var/lib/mysql \
# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
    && chmod 1777 /var/lib/mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && true

# Include the Enve tool
ARG ENVE_VERSION=1.4.1

RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /tmp/enve.tar.gz \
        "https://github.com/joseluisq/enve/releases/download/v${ENVE_VERSION}/enve_v${ENVE_VERSION}_linux_$dpkgArch.tar.gz" \
    && tar xzvf /tmp/enve.tar.gz -C /usr/local/bin enve \
    && enve -v \
    && rm -rf /tmp/enve.tar.gz \
    && chmod +x /usr/local/bin/enve \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && true

COPY 8.0/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY 8.0/scripts/. /usr/local/bin/

VOLUME [ "/var/lib/mysql" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "mysql" ]

# Metadata
LABEL org.opencontainers.image.vendor="Jose Quintana" \
    org.opencontainers.image.url="https://github.com/joseluisq/docker-mysql-client" \
    org.opencontainers.image.title="Docker MySQL 8 Client" \
    org.opencontainers.image.description="MySQL 8 client for export and import databases easily using Docker" \
    org.opencontainers.image.version="v${VERSION}" \
    org.opencontainers.image.documentation="https://github.com/joseluisq/docker-mysql-client/blob/master/README.md"
