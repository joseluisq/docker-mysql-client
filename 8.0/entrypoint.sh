#!/bin/sh

# Path: /usr/local/bin/docker-entrypoint.sh

set -e

# Check if incomming command contains flags.
if [ "${1#-}" != "$1" ]; then
    set -- mysql "$@"
fi

exec "$@"
