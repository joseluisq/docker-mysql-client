#!/bin/bash

START=`date +%s`

XDB_PROTO="$DB_PROTOCOL"
XDB_HOST="$DB_HOST"
XDB_PORT="$DB_PORT"
XDB_DEFAULT_CHARACTER_SET="$DB_DEFAULT_CHARACTER_SET"
XDB_EXPORT_FILE="$DB_EXPORT_FILE_PATH"
XDB_EXPORT_GZIP="$DB_EXPORT_GZIP"
XDB_EXPORT=

# Required env variables
if [[ -z "$DB_NAME" ]]; then "ERROR: `DB_NAME` env variable is required."; exit 1; fi
if [[ -z "$DB_USERNAME" ]]; then "ERROR: `DB_USERNAME` env variable is required."; exit 1; fi
if [[ -z "$DB_PASSWORD" ]]; then "ERROR: `DB_PASSWORD` env variable is required."; exit 1; fi

# Optional env variables
if [[ -z "$XDB_PROTO" ]]; then XDB_PROTO="tcp"; fi
if [[ -z "$XDB_HOST" ]]; then XDB_HOST="127.0.0.1"; fi
if [[ -z "$XDB_PORT" ]]; then XDB_PORT="3306"; fi
if [[ -z "$XDB_DEFAULT_CHARACTER_SET" ]]; then XDB_DEFAULT_CHARACTER_SET=utf8; fi
if [[ -z "$DB_EXPORT_FILE_PATH" ]]; then XDB_EXPORT_FILE="./$DB_NAME.sql"; fi
if [[ -n "$XDB_EXPORT_GZIP" ]] && [[ "$XDB_EXPORT_GZIP" = "true" ]]; then
    if [[ -z $DB_EXPORT_FILE_PATH ]]; then XDB_EXPORT_FILE="$XDB_EXPORT_FILE.gz"; fi

    XDB_EXPORT="| gzip -c > $XDB_EXPORT_FILE"
else
    XDB_EXPORT="> $XDB_EXPORT_FILE"
fi

DB_PASSWORD=$(echo -n $DB_PASSWORD | sed 's/"/\\"/g')

CMD="\
--protocol=$XDB_PROTO \
--host=$XDB_HOST \
--port=$XDB_PORT \
--default-character-set=$XDB_DEFAULT_CHARACTER_SET \
--user=$DB_USERNAME \
--password="\"$DB_PASSWORD"\" \
$DB_ARGS $DB_NAME $XDB_EXPORT"

echo "MySQL 8 Client - Exporter"
echo "========================="

mysqldump --version

echo
echo "Exporting database \`$DB_NAME\` into a SQL script file..."

if [[ -n "$XDB_EXPORT_GZIP" ]] && [[ "$XDB_EXPORT_GZIP" = "true" ]]; then
    echo "Output file: $XDB_EXPORT_FILE (SQL GZipped)"
else
    echo "Output file: $XDB_EXPORT_FILE (SQL Text)"
fi

OUTPUT=$(eval mysqldump ${CMD} 2>&1)
exitcode=$?

if [[ $exitcode != 0 ]]; then echo $OUTPUT; exit $exitcode; fi

# Note: Ugly workaround here because `mysqldump` (unlike `mysql`) doesn't emit a proper exit code even in MySQL v8
# See https://bugs.mysql.com/bug.php?id=90538
if echo $OUTPUT | grep -qE '(.*)(mysqldump: Got error:|: eval:)(.*)'; then
    echo $OUTPUT
    exit 1
fi

if [[ ! -z "$OUTPUT" ]]; then echo $OUTPUT; fi;

FILE_SIZE=$(du -sh $XDB_EXPORT_FILE | cut -f1)

END=`date +%s`
RUNTIME=$((END-START))

echo "Database \`$DB_NAME\` was exported on ${RUNTIME}s successfully!"

if [[ -n "$XDB_EXPORT_GZIP" ]] && [[ "$XDB_EXPORT_GZIP" = "true" ]]; then
    echo "File exported: $XDB_EXPORT_FILE ($FILE_SIZE / SQL GZipped)"
else
    echo "File exported: $XDB_EXPORT_FILE ($FILE_SIZE / SQL Text)"
fi
