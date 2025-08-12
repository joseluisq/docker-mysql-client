#!/bin/bash

set -e

START=`date +%s`

XDB_PROTO="$DB_PROTOCOL"
XDB_HOST="$DB_HOST"
XDB_PORT="$DB_PORT"
XDB_DEFAULT_CHARACTER_SET="$DB_DEFAULT_CHARACTER_SET"
XDB_IMPORT_FILE="$DB_IMPORT_FILE_PATH"
XDB_IMPORT_GZIP="$DB_IMPORT_GZIP"
XDB_IMPORT=

# Required env variables
if [[ -z "$DB_NAME" ]]; then echo "ERROR: 'DB_NAME' env variable is required."; exit 1; fi
if [[ -z "$DB_USERNAME" ]]; then echo "ERROR: 'DB_USERNAME' env variable is required."; exit 1; fi
if [[ -z "$DB_PASSWORD" ]]; then echo "ERROR: 'DB_PASSWORD' env variable is required."; exit 1; fi
if [[ -z "$DB_IMPORT_FILE_PATH" ]]; then echo "ERROR: 'DB_IMPORT_FILE_PATH' env variable is required."; exit 1; fi

# Optional env variables
if [[ -z "$XDB_PROTO" ]]; then XDB_PROTO="tcp"; fi
if [[ -z "$XDB_HOST" ]]; then XDB_HOST="127.0.0.1"; fi
if [[ -z "$XDB_PORT" ]]; then XDB_PORT="3306"; fi
if [[ -z "$XDB_DEFAULT_CHARACTER_SET" ]]; then XDB_DEFAULT_CHARACTER_SET=utf8; fi
if [[ -n "$XDB_IMPORT_GZIP" ]] && [[ "$XDB_IMPORT_GZIP" = "true" ]]; then
    XDB_IMPORT="gzip -dc $XDB_IMPORT_FILE |"
    XDB_IMPORT_FILE=
else
    XDB_IMPORT_FILE="< $XDB_IMPORT_FILE"
fi

DB_PASSWORD=$(echo -n $DB_PASSWORD | sed 's/"/\\"/g')

CMD="\
--protocol=$XDB_PROTO \
--host=$XDB_HOST \
--port=$XDB_PORT \
--default-character-set=$XDB_DEFAULT_CHARACTER_SET \
--user=$DB_USERNAME \
--password="\"$DB_PASSWORD"\" \
$DB_ARGS $DB_NAME $XDB_IMPORT_FILE"

echo "MySQL 8 Client - Importer"
echo "========================="

mysql --version

FILE_SIZE=$(du -sh $DB_IMPORT_FILE_PATH | cut -f1)

echo
echo "Importing a SQL script file into database \`$DB_NAME\`..."

if [[ -n "$XDB_IMPORT_GZIP" ]] && [[ "$XDB_IMPORT_GZIP" = "true" ]]; then
    echo "Input file: $DB_IMPORT_FILE_PATH ($FILE_SIZE / SQL GZipped)"
else
    echo "Input file: $DB_IMPORT_FILE_PATH ($FILE_SIZE / SQL Text)"
fi

eval "${XDB_IMPORT}mysql ${CMD}"

END=`date +%s`
RUNTIME=$((END-START))

echo "Database \`$DB_NAME\` was imported on ${RUNTIME}s successfully!"
