# NOTE: Most of the file is borrowed from https://github.com/docker-library/mysql/blob/master/8.0/Dockerfile.debian

FROM debian:12.12-slim

ARG VERSION=0.0.0

# https://repo.mysql.com/apt/debian/pool/mysql-8.0/m/mysql-community/mysql-client_8.0.44-1debian12_amd64.deb
ARG MYSQL_MAJOR=8.0
ARG MYSQL_VERSION=8.0.44-1debian12

ENV VERSION=${VERSION}
ENV MYSQL_MAJOR=${MYSQL_MAJOR}
ENV MYSQL_VERSION=${MYSQL_VERSION}

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
        gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && true

# add gosu for easy step-down from root
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION=1.19

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
        bzip2 \
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

RUN set -eux; \
# pub   rsa4096 2023-10-23 [SC] [expires: 2025-10-22]
#       BCA4 3417 C3B4 85DD 128E  C6D4 B7B3 B788 A8D3 785C
# uid           [ unknown] MySQL Release Engineering <mysql-build@oss.oracle.com>
# sub   rsa4096 2023-10-23 [E] [expires: 2025-10-22]
	key='BCA4 3417 C3B4 85DD 128E C6D4 B7B3 B788 A8D3 785C'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	mkdir -p /etc/apt/keyrings; \
	gpg --batch --export "$key" > /etc/apt/keyrings/mysql.gpg; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" \
    && true

# https://repo.mysql.com/apt/debian/pool/mysql-8.0/m/mysql-community/
RUN set -eux \
    && echo 'deb [ signed-by=/etc/apt/keyrings/mysql.gpg ] http://repo.mysql.com/apt/debian/ bookworm mysql-8.0' > /etc/apt/sources.list.d/mysql.list \
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
ARG ENVE_VERSION=1.6.0

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
