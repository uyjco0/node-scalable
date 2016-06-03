#!/bin/bash

#
# Starting the Confluent Schema Registry:
#    - In order to run it:
#         - ./06_start_schema.sh [IP_PEER]
#
#    - In order to stop it, it is better to do the following (instead of CTL-C):
#         - docker ps
#              - It shows the ID of the container started by the script
#         - docker stop container ID
#
#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#

source utils.sh

# In order to run the container we need Weave enabled
# ---
# Check if the IP of a peer was given
if [ -z "$1" ]; then
        enable_weave
else
        enable_weave "$1"
fi

# Run the container
docker run -it --rm --name sr1 -e INSTANCE_NAME=sr1 -e SR_kafkastore.connection.url=zk1:2181 -p 8081:8081 uyjco0/confluent-schema:01
