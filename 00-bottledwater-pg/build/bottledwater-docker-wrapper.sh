#!/bin/sh

#
# It is a modified script from:
#    - Source:
#         - https://github.com/confluentinc/bottledwater-pg/blob/master/build/bottledwater-docker-wrapper.sh
#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#

set -e

if [ -z $POSTGRES_HOST ]; then

	echo ""
        echo "There was not provided the variable POSTGRES_HOST"
        echo ""
       	exit 1
fi

if [ -z $POSTGRES_PORT ]; then

        export POSTGRES_PORT=5432
fi

if [ -z $POSTGRES_DB ]; then

        echo ""
        echo "There was not provided the variable POSTGRES_DB"
        echo ""
        exit 1
fi

if [ -z $POSTGRES_USER ]; then

        echo ""
        echo "There was not provided the variable POSTGRES_USER"
        echo ""
        exit 1
fi

if [ -z $POSTGRES_USER_PASS ]; then

        echo ""
        echo "There was not provided the variable POSTGRES_USER_PASS"
        echo ""
        exit 1
fi

if [ -z $KAFKA_HOST ]; then

        echo ""
        echo "There was not provided the variable KAFKA_HOST"
        echo ""
        exit 1
fi

if [ -z $KAFKA_PORT ]; then

	export KAFKA_PORT=9092
fi

if [ -z $SCHEMA_HOST ]; then

        echo ""
        echo "There was not provided the variable SCHEMA_HOST"
        echo ""
        exit 1
fi

if [ -z $SCHEMA_PORT ]; then

        export SCHEMA_PORT=8081
fi

if [ -z $SLOT_NAME ]; then

        export SLOT_NAME="bottledwater"
fi


POSTGRES_CONNECTION_STRING="host=${POSTGRES_HOST} port=${POSTGRES_PORT} dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_USER_PASS}"

KAFKA_BROKER="${KAFKA_HOST}:${KAFKA_PORT}"

SCHEMA_URL="http://${SCHEMA_HOST}:${SCHEMA_PORT}"

exec /usr/local/bin/bottledwater \
    --postgres="$POSTGRES_CONNECTION_STRING" \
    --broker="$KAFKA_BROKER" \
    --schema-registry="$SCHEMA_URL" \
    --slot="$SLOT_NAME" \
    --output-format="avro" \
    "$@"
