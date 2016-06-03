#!/bin/bash

#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#

RP_CFG_FILE="${CONFLUENT_FOLDER}/etc/kafka-rest/kafka-rest.properties"

# Download the config file, if given a URL
if [ ! -z "$RP_CFG_URL" ]; then
  echo "[RP] Downloading RP config file from ${RP_CFG_URL}"
  curl --location --silent --insecure --output ${RP_CFG_FILE} ${RP_CFG_URL}
  if [ $? -ne 0 ]; then
    echo "[RP] Failed to download ${RP_CFG_URL} exiting."
    exit 1
  fi
fi

/usr/sbin/docker-edit-properties --file ${RP_CFG_FILE} --include 'KAFKA_REST_(.*)' --include 'RP_(.*)' --exclude '^RP_CFG_'

# Fix for issue #77, PR #78: https://github.com/confluentinc/kafka-rest/pull/78/files
sed -i 's/\"kafka\"//' ${CONFLUENT_FOLDER}/bin/kafka-rest-run-class

# HACK This is a total hack to get around launching several containers at once. This give zookeeper and kafka time to start.
sleep 10

exec ${CONFLUENT_FOLDER}/bin/kafka-rest-start ${RP_CFG_FILE}
