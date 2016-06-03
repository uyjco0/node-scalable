#!/bin/bash

#
# Starting a node-web cluster using an external pooling service for the PostgreSQL cluster:
#    - In order to run it with fresh data (i.e. deleting an existing volume):
#         - ./09_start_nodeweb.sh node-scalable/04-app/nodeapp dbwebg1 y [IP_PEER]
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

# The current script expects 3 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=3

# Check the number of arguments received and that they are not empty
if [ "$#" -lt "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo 
    	echo "It is needed:"
        echo "  1. The local path to the application sources"
    	echo "  2. The volume name for the applications logs"
    	echo "  3. The option if delete the volume logs if it already exists .."
    	echo
	
	# Finishes the current script
	exit 1
fi

# Check the argument format
if [ "$3" != "y" ] && [ "$3" != "n" ]; then
	echo
        echo "The third argument has invalid format, it is 'y' or 'n' .."
        echo

	# Finishes the current script
        exit 1
fi

# In order to run the container we need Weave enabled
# ---
# Check if the IP of a peer was given
if [ -z "$4" ]; then
        enable_weave
else
        enable_weave "$4"
fi

enable_volume $2 $3

# Run the container
docker run -it --rm --name webg1 -e INSTANCE_NAME=webg1 -e DB_HOST=pool1 -e MEMORY_PROFILING=n -e PORT=80 -p 80:80 -v "$1":/opt/nodeapp:rw -v "$2":/var/log/nodeapp:rw uyjco0/node-web:01
