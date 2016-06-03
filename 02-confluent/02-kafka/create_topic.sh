#!/bin/bash

#
# It is creating a topic in Apache Kafka
#
#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#

# The current script expects 5 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=5

# Check the number of arguments received and that they are not empty
if [ "$#" -ne "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
        echo 
        echo "It is needed:"
        echo "  1. The Zookeeper's hostname"
	echo "  2. The Zookeeper's port"
        echo "  3. The replication factor"
        echo "  4- The partition 's number"
        echo "  5. The topic 's name .."
        echo

        # Finishes the current script
        exit 1
fi

"$CONFLUENT_FOLDER"/bin/kafka-topics --create --zookeeper "$1:$2" --replication-factor "$3" --partitions "$4" --topic "$5"
