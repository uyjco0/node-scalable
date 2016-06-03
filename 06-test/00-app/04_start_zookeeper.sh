#!/bin/bash

#
# Starting the Confluent Zookeeper server:
#    - In order to run it with fresh data (i.e. deleting an existing volume):
#         - ./04_start_zookeeper.sh dbzk1lib y dbzk1log y [IP_PEER]
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

# The current script expects 4 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=4

# Check the number of arguments received and that they are not empty
if [ "$#" -lt "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
	echo 
    	echo "It is needed:"
    	echo "  1. The volume name for the data"
    	echo "  2. The option if delete the volume data if it already exists"
        echo "  3. The volume name for the server application logs"
        echo "  4. The option if delete the volume logs if it already exists .."
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

# In order to run the container we need Weave enabled
# ---
# Check if the IP of a peer was given
if [ -z "$5" ]; then
        enable_weave
else
        enable_weave "$5"
fi

enable_volume $1 $2

enable_volume $3 $4

# Run the container
docker run -it --rm --name zk1 -e INSTANCE_NAME=zk1 -e zk_id=1 -v "$1":/var/lib/zookeeper:rw -v "$3":/var/log/zookeeper -p 2181:2181 uyjco0/confluent-zookeeper:01
