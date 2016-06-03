#!/bin/bash

#
# Starting the Confluent Rest Proxy:
#    - In order to run it:
#         - ./07_start_rest.sh [IP_PEER]
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
docker run  -it --rm --name rp1 -e INSTANCE_NAME=rp1 -e RP_id=1 -e RP_zookeeper.connect=zk1:2181 -e RP_schema.registry.url=http://sr1.weave.local:8081 -p 8082:8082 uyjco0/confluent-rest:01
