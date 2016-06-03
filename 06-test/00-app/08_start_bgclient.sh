#!/bin/bash

#
# Starting the Bottled Water Client:
#    - In order to run it:
#         - ./08_start_bgclient.sh [IP_PEER]
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
docker run -it --rm --name bwclient1 -e INSTANCE_NAME=bwclient1 -e POSTGRES_HOST=pg1 -e POSTGRES_PORT=5432 -e POSTGRES_USER=challenge -e POSTGRES_USER_PASS=challenge -e POSTGRES_DB=challenge -e KAFKA_HOST=kf1 -e KAFKA_PORT=9092 -e SCHEMA_HOST=sr1.weave.local -e SCHEMA_PORT=8081 uyjco0/bw-client:01
