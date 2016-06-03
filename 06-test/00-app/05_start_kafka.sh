#!/bin/bash

#
# Starting the Confluent Kafka server:
#    - In order to run it with fresh data (i.e. deleting an existing volume):
#         - ./05_start_kafka.sh dbkf1lib y dbkf1log y dbkf1sec y [IP_PEER]
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

# The current script expects 6 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=6

# Check the number of arguments received and that they are not empty
if [ "$#" -lt "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ]; then
	echo 
    	echo "It is needed:"
    	echo "  1. The volume name for the data"
    	echo "  2. The option if delete the volume data if it already exists"
        echo "  3. The volume name for the server application logs"
        echo "  4. The option if delete the volume logs if it already exists"
        echo "  5. The volume name for the server application security"
        echo "  6. The option if delete the volume security if it already exists .."
    	echo
	
	# Finishes the current script
	exit 1
fi

# Check the argument format
if [ "$2" != "y" ] && [ "$2" != "n" ]; then
	echo
        echo "The second argument has invalid format, it is 'y' or 'n' .."
        echo

	# Finishes the current script
        exit 1
fi

# Check the argument format
if [ "$4" != "y" ] && [ "$4" != "n" ]; then
        echo
        echo "The fourth argument has invalid format, it is 'y' or 'n' .."
        echo

        # Finishes the current script
        exit 1
fi

# Check the argument format
if [ "$6" != "y" ] && [ "$6" != "n" ]; then
        echo
        echo "The sixth argument has invalid format, it is 'y' or 'n' .."
        echo

        # Finishes the current script
        exit 1
fi

# In order to run the container we need Weave enabled
# ---
# Check if the IP of a peer was given
if [ -z "$7" ]; then
        enable_weave
else
        enable_weave "$7"
fi

enable_volume $1 $2

enable_volume $3 $4

enable_volume $5 $6

# Run the container
docker run -it --rm --name kf1 -e INSTANCE_NAME=kf1 -e KAFKA_BROKER_ID=1 -e KAFKA_ZOOKEEPER_CONNECT=zk1:2181 -e KAFKA_advertised.host.name=kf1.weave.local -e KAFKA_advertised.port=9092 -e KAFKA_num.partitions=60 -p 9092:9092 -v "$1":/var/lib/kafka:rw -v "$3":/var/log/kafka:rw -v "$5":/etc/security:rw uyjco0/confluent-kafka:01
