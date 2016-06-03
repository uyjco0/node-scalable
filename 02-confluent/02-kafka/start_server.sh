#!/bin/bash

#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#

KAFKA_CFG_FILE="${CONFLUENT_FOLDER}/etc/kafka/server.properties"

: ${KAFKA_BROKER_ID:=0}

# Force the data directory and log paths to our volumes.
export KAFKA_LOG_DIRS='/var/lib/kafka'
export LOG_DIR='/var/log/kafka'

# Download the config file, if given a URL
if [ ! -z "$KAFKA_CFG_URL" ]; then
  echo "[kafka] Downloading Kafka config file from ${KAFKA_CFG_URL}"
  curl --location --silent --insecure --output ${KAFKA_CFG_FILE} ${KAFKA_CFG_URL}
  if [ $? -ne 0 ]; then
    echo "[kafka] Failed to download ${KAFKA_CFG_URL} exiting."
    exit 1
  fi
fi

/usr/sbin/docker-edit-properties --file ${KAFKA_CFG_FILE} --include 'KAFKA_(.*)' --exclude '^KAFKA_LOGS' --exclude '^KAFKA_CFG_'

export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:${CONFLUENT_FOLDER}/etc/kafka/log4j.properties"

exec ${CONFLUENT_FOLDER}/bin/kafka-server-start ${KAFKA_CFG_FILE}
