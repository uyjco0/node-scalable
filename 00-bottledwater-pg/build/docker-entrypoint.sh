#!/bin/bash

#
# It is a modified script from:
#    - Source:
#         - https://github.com/docker-library/postgres/blob/8e867c8ba0fc8fd347e43ae53ddeba8e67242a53/9.5/docker-entrypoint.sh
#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#

set -e

if [ "${1:0:1}" = '-' ]; then
	set -- postgres "$@"
fi

if [ "$1" = 'postgres' ]; then

	# **************************
	# **** SCRIPT VARIABLES ****
	# **************************

	if [ $REPLICATION -eq 1 -a $MASTER -ne 1 ] && [ -z $POSTGRES_MASTER ]; then
                echo ""
                echo "There was not provided the master 's hostname"
                echo ""
                exit 1
        fi

	export POSTGRES_HOST=$INSTANCE_NAME
	
	# The name of the Physical Slot for replication
	export SLOT_NAME="scale_reads"

	# The name used for Synchronous Streaming replication
	export SYN_STANDBY_NAME="syn_scale_reads"

	if [ -z $POSTGRES_PORT ]; then
        	export POSTGRES_PORT=5432
	fi

	if [ -z $POSTGRES_USER ]; then
		export POSTGRES_USER="challenge"
	fi

	if [ -z $POSTGRES_PASSWORD ]; then
		export POSTGRES_PASSWORD="challenge"
	fi

	if [ -z $POSTGRES_DB ]; then
		export POSTGRES_DB="challenge"
	fi

	# Bottled Water Plugin & Master parameters
	export MAX_WAL_SENDERS=8
        export WAL_KEEP_SEGMENTS=4
        export MAX_REPLICATION_SLOTS=4

	
	mkdir -p "$PGDATA"

	chmod g+s /run/postgresql
	chown -R postgres /run/postgresql

	if [ $REPLICATION -eq 1 -a $MASTER -eq 0 ]; then

		echo ""
		echo "**********************************"
                echo "CONFIGURING REPLICATION-SLAVE ...."
                echo "**********************************"
	
		if [ -f "/usr/share/base-backup/nobase.txt" ]; then

			echo ""
			echo "It was not provided a base backup at the volume: /usr/share/base-backup/"
			echo "So it is being generated an online base backup by using the utility: pg_basebackup"
			echo "Be patient, it could take a while to complete ..."
			echo "" 
			
			# Generate a base backup from the master
                	pg_basebackup --pgdata="$PGDATA" --dbname="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_MASTER" --xlog-method="stream" --progress
			echo ""
		else
			# Copy the base backup files
			cp -r /usr/share/base-backup/. $PGDATA
		fi
	
		# We need fresh configuration files
		cp /usr/share/fresh-config/postgresql.conf $PGDATA
                cp /usr/share/fresh-config/pg_hba.conf $PGDATA

		# Configuring the PostgreSQL port:
		sed -i.old \
    		    -e "s/#* *port *= *[0-9]*/port = $POSTGRES_PORT/" \
    	            "${PGDATA}/postgresql.conf"

		# Configure default access to the slave
		echo "host all all 0.0.0.0/0 md5"  >> "$PGDATA/pg_hba.conf"

                # Enable replication (i.e. make it a slave)
                echo "standby_mode = 'on'" > "${PGDATA}/recovery.conf"
		if [ $ASYNC -eq 1 ]; then
                	echo "primary_conninfo = 'host=$POSTGRES_MASTER port=$POSTGRES_PORT user=$POSTGRES_USER password=$POSTGRES_PASSWORD'" >> "${PGDATA}/recovery.conf"
		else
			echo "primary_conninfo = 'host=$POSTGRES_MASTER port=$POSTGRES_PORT user=$POSTGRES_USER password=$POSTGRES_PASSWORD application_name=$SYN_STANDBY_NAME'" >> "${PGDATA}/recovery.conf"
		fi
                echo "primary_slot_name = '$SLOT_NAME'" >> "${PGDATA}/recovery.conf"

                # Make the slave able to serve read queries
                sed -i.old \
                    -e 's/#* *hot_standby *= *[a-z]*/hot_standby = on/' \
                    "${PGDATA}/postgresql.conf"

		# Give the needed permissions to start the server
		chmod 700 "$PGDATA"
                chown -R postgres "$PGDATA"

		exec gosu postgres "$@"

	else
		# look specifically for PG_VERSION, as it is expected in the DB dir
		if [ ! -s "$PGDATA/PG_VERSION" ]; then

			chmod 700 "$PGDATA"
        		chown -R postgres "$PGDATA"

			eval "gosu postgres initdb $POSTGRES_INITDB_ARGS"

			# check password first so we can output the warning before postgres
			# messes it up
			if [ "$POSTGRES_PASSWORD" ]; then
				pass="PASSWORD '$POSTGRES_PASSWORD'"
				authMethod=md5
			else
				# The - option suppresses leading tabs but *not* spaces. :)
				cat >&2 <<-'EOWARN'
					****************************************************
					WARNING: No password has been set for the database.
				        	 This will allow anyone with access to the
				         	 Postgres port to access your database. In
				         	 Docker's default configuration, this is
				         	 effectively any other container on the same
				         	 system.
				         	 Use "-e POSTGRES_PASSWORD=password" to set
				         	 it in "docker run".
					****************************************************
				EOWARN

				pass=
				authMethod=trust
			fi

			{ echo; echo "host all all 0.0.0.0/0 $authMethod"; } >> "$PGDATA/pg_hba.conf"

			# internal start of server in order to allow set-up using psql-client		
			# does not listen on external TCP/IP and waits until start finishes
			gosu postgres pg_ctl -D "$PGDATA" \
				-o "-c listen_addresses='localhost'" \
				-w start

			: ${POSTGRES_USER:=postgres}
			: ${POSTGRES_DB:=$POSTGRES_USER}
			export POSTGRES_USER POSTGRES_DB

			psql=( psql -v ON_ERROR_STOP=1 )

			if [ "$POSTGRES_DB" != 'postgres' ]; then
				"${psql[@]}" --username postgres <<-EOSQL
					CREATE DATABASE "$POSTGRES_DB" ;
				EOSQL
				echo
			fi

			if [ "$POSTGRES_USER" = 'postgres' ]; then
				op='ALTER'
			else
				op='CREATE'
			fi
			"${psql[@]}" --username postgres <<-EOSQL
				$op USER "$POSTGRES_USER" WITH SUPERUSER $pass ;
			EOSQL
			echo

			psql+=( --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" )

			echo
			for f in /docker-entrypoint-initdb.d/*; do
				case "$f" in
					*.sh)     echo "$0: running $f"; . "$f" ;;
					*.sql)    echo "$0: running $f"; "${psql[@]}" < "$f"; echo ;;
					*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${psql[@]}"; echo ;;
					*)        echo "$0: ignoring $f" ;;
				esac
				echo
			done

			gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

			echo
			echo 'PostgreSQL init process complete; ready for start up.'
			echo
		fi

		exec gosu postgres "$@"
	fi
fi

exec "$@"
