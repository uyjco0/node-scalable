#!/bin/bash

#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#


set -e

# *******************************
# **** GENERAL CONFIGURATION ****
# *******************************


# Configuring the PostgreSQL port:
sed -i.old \
    -e "s/#* *port *= *[0-9]*/port = $POSTGRES_PORT/" \
    "${PGDATA}/postgresql.conf"



# ******************************
# **** BOTTLED WATER PLUGIN ****
# ******************************


if [ $REPLICATION -eq 0 ] || [ $REPLICATION -eq 1 -a $MASTER -eq 1 ]; then

	echo ""
	echo "************************************"
	echo "CONFIGURING BOTTLED WATER PLUGIN ..."
	echo "************************************"
	echo ""

	# Configuring the Bottled Water plugin:
	#    - Source:
	#         - https://github.com/confluentinc/bottledwater-pg
	sed -i.old \
    	    -e 's/#* *wal_level *= *[a-z]*/wal_level = logical/' \
    	    -e "s/#* *max_wal_senders *= *[0-9]*/max_wal_senders = $MAX_WAL_SENDERS/" \
    	    -e "s/#* *wal_keep_segments *= *[0-9]*/wal_keep_segments = $WAL_KEEP_SEGMENTS/" \
    	    -e "s/#* *max_replication_slots *= *[0-9]*/max_replication_slots = $MAX_REPLICATION_SLOTS/" \
    	    "${PGDATA}/postgresql.conf"


	# Adding replication privileges for the database for the Bottled Water Plugin:
	#    - Source:
	#         - https://github.com/confluentinc/bottledwater-pg
	echo "host replication $POSTGRES_USER 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"


	# Enable the Bottled Water plugin:
	#   - Add the 'REPLICATION' privilege to the user that the Bottle Water client will use
	#   - Enable the Bottled Water extension
	psql --username "$POSTGRES_USER" <<-EOSQL
    		ALTER USER "$POSTGRES_USER" WITH REPLICATION;
    		CREATE EXTENSION bottledwater;
	EOSQL

fi


# *********************
# **** REPLICATION ****
# *********************


# Checking if it is needed to configure replication:
#    - If it is needed, then it is configuring Streaming Replication with a Physical Replication Slot:
#         - If the variable ASYNC is set to 1, then Asynchronous Streaming Replication is configured:
#              - Otherwise Synchronous Streaming Replication is configured
if [ $REPLICATION -eq 1 ]; then

	if [ $MASTER -eq 1 ]; then

		echo ""
		echo "***********************************"
		echo "CONFIGURING REPLICATION-MASTER ...."
		echo "***********************************"
		echo ""
      
		# The configuration added for the Bottled Water Plugin in the 'postgresql.conf'
                # and the 'pg_hba.conf' is enough for the master:
                #    - 'postgresql.conf':
                #         - 'wal_leve': it needs to be 'hot_standby' or higher
                #         - 'max_wal_senders': high enough to support enough slaves
                #         - 'max_replication_slots': at least 2 (bw-plugin and replication) 
                #    - 'pg_hba.conf':
                #         - Add connection access to a user with replication privileges


		

		# Adding needed configuration for the case of Synchronous Streaming Replication
		if [ $ASYNC -ne 1 ]; then

			sed -i.old \
                	    -e "s/#* *synchronous_standby_names *= *''/synchronous_standby_names = $SYN_STANDBY_NAME/" \
			    -e "s/#* *synchronous_commit *= *[a-z]*/synchronous_commit = $COMMIT_LEVEL/" \
    			    "${PGDATA}/postgresql.conf"
		fi

		

		# Create the physical replication slot with name $SLOT_NAME
       		psql --username "$POSTGRES_USER" <<-EOSQL
			SELECT * FROM pg_create_physical_replication_slot('$SLOT_NAME');
		EOSQL
       	fi
fi
