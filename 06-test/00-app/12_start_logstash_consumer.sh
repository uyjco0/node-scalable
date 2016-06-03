#!/bin/bash

#
# It is starting Logstash as a particular kind of 'Worker' that is an Apache Kafka consumer:
#    - In order to run it:
#         - ./12_start_logstash_consumer.sh node-scalable/05-logstash/00-logstash/logstash-consumer.conf [IP_PEER]
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

# The current script expects 1 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=1

# Check the number of arguments received and that they are not empty
if [ "$#" -lt "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ]; then
        echo 
        echo "It is needed:"
        echo "  1. The path to where is located the Logstash configuration file .."
        echo

        # Finishes the current script
        exit 1
fi


# In order to run the container we need Weave enabled
# ---
# Check if the IP of a peer was given
if [ -z "$2" ]; then
        enable_weave
else
        enable_weave "$2"
fi

# Run the container
docker run -it --rm --name lstash2 -e INSTANCE_NAME=lstash2 -e BOOTSTRAP_SERVERS="kf1:9092" -v "$1":/etc/logstash/logstash-consumer.conf uyjco0/logstash:01 logstash --config /etc/logstash/logstash-consumer.conf --allow-env
