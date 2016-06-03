#!/bin/bash

#
# It is starting Logstash as a particular kind of 'Worker' that is an Apache Kafka 's producer:
#    - In order to run it:
#         - ./11_start_logstash_producer.sh y dbpg1 dbpg2 dbpool1 dbzk1log dbkf1log dbwebg1 dbworkerg1 node-scalable/05-logstash/00-logstash/logstash-producer.conf [IP_PEER]
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

# The current script expects 9 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=9

# Check the number of arguments received and that they are not empty
if [ "$#" -lt "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] || [ -z "$7" ] || [ -z "$8" ] || [ -z "$9" ]; then
	echo 
    	echo "It is needed:"
        echo "  1. The option if create the topic or not"
        echo "  2. The name of the volume with the logs for the Master PostgreSQL server"
    	echo "  3. The name of the volume with the logs for the Slave PostgreSQL server"
        echo "  4. The name of the volume with the logs for the Pooling service"
        echo "  5. The name of the volume with the logs for the Apache Zookeper server"
        echo "  6. The name of the volume with the logs for the Apache Kafka server"
        echo "  7. The name of the volume with the logs for the node-web cluster"
    	echo "  8. The name of the volume with the logs for the node-worker cluster"
        echo "  9. The path to where is located the Logstash configuration file .."
    	echo
	
	# Finishes the current script
	exit 1
fi

# Check the argument format
if [ "$1" != "y" ] && [ "$1" != "n" ]; then
        echo
        echo "The first argument has invalid format, it is 'y' or 'n' .."
        echo

        # Finishes the current script
        exit 1
fi

# In order to run the container we need Weave enabled
# ---
# Check if the IP of a peer was given
if [ -z "$10" ]; then
        enable_weave
else
        enable_weave "$10"
fi

if [ "$1" == "y" ]; then
	# Create the 'logstash' topic in Apache Kafka
	docker run -ti --rm --entrypoint=/usr/sbin/create_topic.sh uyjco0/confluent-kafka:01 zk1 2181 1 1 logstash
fi

# Run the container
docker run -it --rm --name lstash1 -e INSTANCE_NAME=lstash1 -e BOOTSTRAP_SERVERS="kf1:9092" -v "$2":/var/log/postgres1:rw -v "$3":/var/log/postgres2:rw -v "$4":/var/log/pooling1:rw -v "$5":/var/log/zookeeper1:rw -v "$6":/var/log/kafka1:rw -v "$7":/var/log/node-web1:rw -v "$8":/var/log/node-worker1:rw -v "$9":/etc/logstash/logstash-producer.conf uyjco0/logstash:01 logstash --config /etc/logstash/logstash-producer.conf --allow-env
