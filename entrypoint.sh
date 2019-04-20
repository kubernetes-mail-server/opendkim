#!/usr/bin/env sh

function required () {
    eval v="\$$1";

    if [ -z "$v" ]; then
        echo "$1 envvar is not configured, exiting..."
        exit 0;
    else
        [ ! -z "${ENTRYPOINT_DEBUG}" ] && echo "Rewriting required variable '$1' in file '$2'"
        sed -i "s~{{ $1 }}~$v~g" $2
    fi
}

function optional () {
    eval v="\$$1";

    [ ! -z "${ENTRYPOINT_DEBUG}" ] && echo "Rewriting optional variable '$1' in file '$2'"
    sed -i "s~{{ $1 }}~$v~g" $2
}

for file in $(find /etc/opendkim -type f); do
  required DATABASE_HOSTNAME ${file}
  required DATABASE_PORT ${file}
  required DATABASE_USERNAME ${file}
  required DATABASE_PASSWORD ${file}
  required DATABASE_NAME ${file}
  required DATABASE_TABLE_KEYS ${file}
  required DATABASE_TABLE_SIGNING ${file}
  required RELAY_NETS ${file}
done

echo "Running '$@'"
exec $@
