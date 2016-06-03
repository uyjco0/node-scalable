#!/bin/bash

#
# Starting a Slave PostgreSQL with Asynchronous replication:
#    - In order to run it with fresh data (i.e. deleting an existing volume):
#         - ./02_start_slave_pg.sh dbpg2 y [IP_PEER]
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

# The current script expects 2 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=2

# Check the number of arguments received and that they are not empty
if [ "$#" -lt "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ] || [ -z "$2" ]; then
	echo 
    	echo "It is needed:"
    	echo "  1. The volume name"
    	echo "  2. The option if delete the volume if it already exists .."
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

# In order to run the container we need Weave enabled
# ---
# Check if the IP of a peer was given
if [ -z "$3" ]; then
        enable_weave
else
        enable_weave "$3"
fi

enable_volume $1 $2

# Run the container
docker run -it --rm --name pg2 -e INSTANCE_NAME=pg2 -e POSTGRES_USER=challenge -e POSTGRES_PASSWORD=challenge -e POSTGRES_DB=challenge -e REPLICATION=1 -e MASTER=0 -e POSTGRES_MASTER=pg1  -p 5433:5432 -v "$1":/var/lib/postgresql/data:rw uyjco0/postgres-bw-plugin:01
