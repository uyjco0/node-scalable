
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate Docker POSTGRESQL images with the BOTTLED WATER PLUGIN enabled:
      - The current PostgreSQL image is a bit flexible, it is possible generate:
           - A standalone PostgreSQL server
           - A Master or Slave for Asynchronous Replication using a Physical Replication Slot
           - A Master or Slave for Synchronous Replication using a Physical Replication Slot
      - The image is also generating the binaries for the BOTTLED WATER CLIENT

-> Here are also the instruction to generate a Docker BOTTLED WATER CLIENT image 


******* SOURCES ******************

-> It is reusing (but modified) code from:
      - https://github.com/confluentinc/bottledwater-pg
      - https://github.com/docker-library/postgres/tree/8e867c8ba0fc8fd347e43ae53ddeba8e67242a53/9.5 


******* NEEDED ******************

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)

-> Creating a named volume:
      - Delete the volume if it already exists (if it is needed):
           - docker volume rm dbpg1
           - docker volume rm dbpg2
           - docker volume rm dbbw1
      - Creating the needed volumes:
           - docker volume create --name dbpg1
           - docker volume create --name dbpg2
           - docker volume create --name dbbw1
      - We can see where is the physical folder in the host for the volume with:
           - docker volume inspect dbpg1


******* GENERATE THE POSTGRES IMAGE WITH THE BOTTLED WATER PLUGIN ******************

-> Run the following command in the folder with the 'Makefile':
      - make docker-build


******* USING THE POSTGRES IMAGE WITH THE BOTTLED WATER PLUGIN ENABLED ******************

-> docker run -d --restart=always --name pg1 -e INSTANCE_NAME=pg1 -e POSTGRES_USER=challenge -e POSTGRES_PASSWORD=challenge -e POSTGRES_DB=challenge -e REPLICATION=0 -e MASTER=1 -p 5432:5432 -v dbbw1:/usr/local/pg-plugin:rw -v dbpg1:/var/lib/postgresql/data:rw uyjco0/postgres-bw-plugin:01


-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'pg1' 
      - POSTGRES_PORT: the port where the PostgreSQL server will be listening
	   - In this case it is needed to change '-p 5432:5432' by:
                - '-p SOME_PORT:POSTGRES_PORT'
           - Default is 5432
      - POSTGRES_USER: the name of the user to be created in the database
           - It will be the owner of the database created (i.e. the database in POSTGRES_DB)
           - Default is 'challenge'
      - POSTGRES_PASSWORD: the password for POSTGRES_USER
           - Default is 'challenge'
      - POSTGRES_DB: the name of the database to be created:
           - Default is 'challenge'
      - REPLICATION: if it is set to 1, then the PostgreSQL server will be configured with Streaming Replication using a Physical Replication Slot:
           - Otherwise a standard PostgreSql server is configured
           - Default is 0
      - ASYNC: if it is set to 1, then Asynchronous Streaming Replication is configured:
           - Otherwise Synchronous Streaming Replication is configured
           - Default is 1
      - COMMIT_LEVEL: it has the value for the parameter 'synchronous_commit' being set when REPLICATION=1 and ASYNC=0:
           - Default is 'remote_write'
      - MASTER: if REPLICATION=1, then it is saying if configure a master (i.e. MASTER=1) or a slave (i.e. MASTER=0):
           - If MASTER=0, then if the master database is big it is recommended the following:
                - Mount a host directory as a data volume on the container folder '/usr/share/base-backup':
                     - As for example '-v some_host_path:/usr/share/base-backup:rw'
                          - This host directory will have a base backup of the master database:
                               - If a host directory with a base backup is not mounted as explained above, then the container will make an online master 's base backup using the utility 'pg_basebackup'
           - Default is 1
      - POSTGRES_MASTER: if REPLICATION=1 and MASTER=0, then it is the hostname where the master is running:
           - If it is not provided when needed, the configuration is aborted with error



******* CONFIG FILES USED IN THE POSTGRES IMAGE WITH THE BOTTLED WATER PLUGIN ******************

-> First it is described the physical requirements of the PostgreSQL servers, because these requirements are defining the parameters in the configuration files:
      0. Assuming the following:
           a. 2.000.000 write requests a day:
                - i.e. 25 write requests per second
           b. Each write request is loading as an average a CSV file with 10.000 lines:
                 - The statistics for this file are the following:
                      - The file has a size of 700 K:
                           - The file is generated using the following command:
                                node-scalable/06-test/01-stest/create_file.py -f test.csv -l 10000
                      - The file takes 10 ms to load in the database (with the current implementation of 'node-web')
                 - The statistics for other CSV files:
                      - 3 lines: size: 4 K / load time: 1.2 ms
                      - 100 lines: size: 8 K / load time: 1.7 ms
                      - 1000 lines: size: 68 K / load time: 3 ms
                      - 5000 lines: size: 340 K / load time: 7 ms
                      - 25000 lines: size: 1.7 MB / load time 14 ms
      1. Estimating the database size (i.e estimating the amount of disk size):
           - The volume of data being generated each day:
                - Using as a base 2.000.000 daily requests, and each one loading the size of a CSV file with 10.000 lines (i.e. 700 K):
                     - (((700/1024)*2000000)/1024)/1024 = 1.3 Terabytes
                          - Then, the volume of data being generated each year:
                               - (1.3*365)/1024 = 0.46 Petabytes
      2. Estimating the amount of RAM size per host:
           - The ideal RAM 's size for a server instance is the one that is able to hold the entire database in memory:
                - According to the estimated database size that is not possible,
                     - Then it is needed to use a smaller size of RAM:
                          - The reads are mainly from the last write, so we can provision a RAM that is able to hold 1 hour of the workload:
                               - Using as a base the 25 write requests each second, and each write request loading 700 K:
                                    - Then, in a second the workload is (700/(1024*1024))*25 = 0.017 GB:
                                         - The workload for 5 minutes is 0.017*60*60 = 61 GB
                          - Using the above calculations the RAM size should be 64 GB
      3. Estimating the number of hosts:
           - Master server (i.e. write requests):
                - Assuming the worst we can assume that each request is taking 100 ms (instead of the 10 ms that was calculated previously loading a CSV file with 10.000 lines):
                     - Then, each database connection is able to manage 1000/100 = 10 write requests per second:
                          - So, with 3 parallel database connections it is possible to manage the 25 write requests per second:
                               - Then it is possible  manage this load (and much more) in the single Master PostgreSQL server:
                                    - That is good, because with a Master/Slave configuration, it is not possible to scale horizontally the master:
                                         - Because only one master a time is able to process all the requests, so it is a bottleneck for scaling horizontally:
                                              - In the case that vertical scaling is not enough, then it is needed to change the configuration from Master/Slave to Sharding:
                                                   - For that, it is needed for the current table analyze which field is the most appropiated for the hashing partitioning (i.e.
                                                     in order to balance the different shards)
           - Slave server (i.e. read requests):
                - Each write request is generating 10.000 read requests per second (i.e. each line in the loaded CSV file is generating a read request):
                     - Then for 25 write requests per seconds we are having 25*10000 = 250.000 read requests per second:
                          - PostgreSQL benchmarks:
                               1. http://akorotkov.github.io/blog/2016/05/09/scalability-towards-millions-tps:
                                     - Performance is improving with the current 9.6 beta version
                               2. http://amitkapila16.blogspot.ru/2015/01/read-scalability-in-postgresql-95.html:
                                     - 400.000 TPS in a server with 24 cores and 492GB RAM (here the data fit the RAM)
                          - Here it is not possible to hold all the database in RAM, but it is possible to have the workload of the last hour that could be enough (i.e. a RAM of 64 GB):
                               - 250.000 TPS < 400.000 TPS, then it would be enough with 2 physical servers:
                                    - Each one with 12 CPUs (cores) and a RAM of 64 GB
                                         - That is not a problem, because it is easy to scale horizontally the slave servers:
                                              - The application is designed, implemented and configurated for that:
                                                   - The best is to cascade the slaves (i.e. Cascade Replication) in order to avoid performance degradation in the master:
                                                        - i.e. most of the slaves replicating from slaves (instead from the master)
                     - Observation:
                          - The application is using database streaming (through the Bottledwater Client), so it already have all the database write data in the 'Message Bus' (i.e. in Apache Kafka):
                               - So, it is possible to minimize the read requests to the database:
                                    - i.e. using only read requests for operations for which the relational database 's design is optimal:
                                         - And using optimized queries and optimized indexes for these queries
           - Total pysical hosts:
                - One for the master server:
                     - We can use the same configuration that the slaves:
                          - 12 CPUs (cores) and a RAM of 64 GB
                - Two for the slave servers:
                     - Each one with 12 CPUs (cores) and a RAM of 64 GB
                - Using that we can set the maximum amount of concurrent connections in each server to 12*3 = 36:  
                     - It is using #_concurrent_connections = 3*#_CPUs:
                          - i.e. rounding to 3 instead of using 2 and the number of disk spindles:
                               - https://wiki.postgresql.org/wiki/Number_Of_Database_Connections
                               - https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing

              
-> The configuration files are:
      - postgresql.conf:
           - The PostgreSQL configuration file
           - Configuration:
                1. The configuration for Master/Slave:
                      - The needed options are set in the following scripts:
                           - build/docker-entrypoint.sh
                           - pg-config/scripts/configure.sh
                2. Performance (using as a base the physical requiremente described above):
                      - Data consistency levels (avoiding database corruption):
                           - fsync = on
                                - When 'on', COMMIT will wait until master has flused to disk
                                  (i.e. to the WAL files) the changes made in the transaction
                           - synchronous_commit = remote_write
                                - When 'remote_write', COMMIT will wait until master has flushed
                                  to disk (i.e. to the WAL files), and slave has accepted the WAL
                                  and passed it to the OS for writing (but without waitin for the
                                  OS confirmation)
                      - Checkpoint (it is sending the data from the WAL to the database's table files):
                           - max_wal_size = 5GB
                                - It means when sending the WAL changes to the database tables
                                  (i.e. to the tables files) and truncating the WAL (in order to
                                  avoid a very big WAL):
                                     - This process is costly because it means flushing the WAL
                                       changes to disk (i.e. to the tables files on disk)
                                - It is replacing the old 'checkpoint_segments' parameter:
                                     - https://www.postgresql.org/docs/9.5/static/release-9-5.html
                                - It is set in function of the assumed worload of (700/1024)*25 MB/sec
                           - min_wal_size = 342MB
                                - It is set in function of the assumed worload of (700/1024)*25 MB/sec:
                                     - It is being hold the last 20 secs
                           - checkpoint_timeout = 6min
                                - It is wanted to flush data the data to disk each time the WAL
                                  has 5GB of new data:
                                     - Assuming that the server is receiving 700k*25=17MB each second:
                                          - That gives an upper bound of (1024*5)/17 = 301s = 5min < 6min
                           - checkpoint_completion_target = 0.85
                                - It is wanted to avoid overwhelm the disk subsystem with a big data flus, 
                                  and this setting will cause PostgreSQL to spread writes over 85 percent 
                                  of the time specified by checkpoint_timeout
                      - Connections (how many concurrent database connections):
                           - max_connections = 36
                                - Setting the maximum amount of concurrent connections in function of the
                                  amount of CPUs (cores):
                                     - max_conn = 3 * #_CPUs:
                                          - i.e. rounding to 3 intead of using 2 and the number of disk spindles:
                                               - https://wiki.postgresql.org/wiki/Number_Of_Database_Connections
                                               - https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing
                                - Here it is assumed a physical host with 12 CPUs (cores)
                      - Memory and planner (how it is being used the RAM and the query planner parameters):
                           - The 'Out of Memory Killer' (OOM-Killer):
                                - http://linux-mm.org/OOM_Killer
                                - It is not in the configuration file:
                                     - The OMM-Killer can cause nasty things when running a PostgreSQL sever:
                                          - If system is only running PostgreSQL (as it is recommended here), then turn 
                                            off overcommit:
                                               - echo "vm.overcommit_memory=2 >> /etc/sysctl.conf
                                                 echo "vm.overcommit_ratio=60 >> /etc/sysctl.conf
                                                 sysctl -p /etc/sysctl.conf
                           - shared_buffers = 16GB
                                - It defines the amount of memory the database server uses for shared memory buffers
                                - It is set approximately to 1/4 of the available RAM:
                                     - In the case of a forced checkpoint, an amount of RAM equal to 'shared_buffers' could 
                                       be flushed to disk:
                                          - Beware that if the RAM is very big, then in the case of a forced checkpoint it 
                                            could overwhelm the disk subsystem
                                - Here it is assumed a server with 64GB of RAM 
                           - work_mem = 16MB
                                - It defines the amount of memory to be used by internal sort operations and hash tables before
                                  switching to temporary disk files
                                - Set it to 8MB for servers with up to 32GB of RAM, 16MB for server with up to 64GB of
                                  RAM, and 32MB for server with more than 64GB of RAM
                                - Here it is assumed a server with 64GB of RAM
                           - maintenance_work_mem = 1GB
                                -  It defines the maximum amount of memory to be used in maintenance operations, such as 
                                   VACUUM, CREATE INDEX
                                - It is set approximately to a fraction of the result of:
                                     50 MB of maintainance_work_mem per GB of server RAM
                                - Here it is assumed a server with 64GB of RAM
                           - effective_cache_size = 32GB
                                -  It sets the planner’s assumption about the effective size of the disk cache that is available
                                   to a single query:
                                      - i.e. it does not allocate any memory, it is strictly used as input on how queries are
                                        executed, and a rough estimate is sufficient for most purposes)
                                - This is factored into estimates of the cost of using an index:
                                     - A higher value makes it more likely index scans will be used
                                     - A lower value makes it more likely sequential scans will be used
                                - It is set approximately to 50% of the available RAM
                                - Here it is assumed a server with 64GB of RAM
                           - random_page_cost = 3.0
                                - It sets the planner's estimate of the cost of a non-sequentially-fetched disk page:
                                     - 3.0 for a typical RAID10 array
                                     - 2.0 for a storage area network
                                     - 1.1 for Amazon EBS
                                     - 1.0 for SSD
                      - Vacuum (it is the garbage-collection, compression and analysing process):
                           - track_counts = on
                                - It is required by the autovacuum subprocess
                           - autovacuum = on
                           - autovacuum_vacuum_cost_limit = -1
                                - It means using 'vacuum_cost_limit'
                           - vacuum_cost_limit = 200
                                - If the autovacuum subprocess is slowing down the system, increase this value
                           - When to run:
                                - Vacuum:
                                     - Parameters:
                                          - autovacuum_vacuum_scale_factor = 0.2
                                          - autovacuum_vacuum_threshold = 50
                                     - Meaning:
                                          - The tables are vacuumed when 20% of the rows plus 50 rows are inserted, updated or deleted:
                                               - This setting work OK when the table is smaller tables, but as a table grows to have millions of rows,
                                                 there can be tens of thousands of inserts or updates before the table is vacuumed and analyzed:
                                                    - When the table is big it is better to set 'autovacuum_vacuum_scale_factor = 0.0' and define some number of
                                                      rows after which the tables will be auto-vacuumed:
                                                         - For example 'autovacuum_vacuum_threshold = 250000'
                                - Analyze:
                                     - Parameters:
                                          - autovacuum_analyze_scale_factor = 0.1
                                          - autovacuum_analyze_threshold = 50
                                     - The tables are analyzed when 10% of the rows plus 50 rows are inserted, updated or deleted:
                                          - Here there is the same observation that for 'Vacuum'

                3. Logging:
                      - The following parameters are useful when the system is new in production:
                           - After a while, some options could be disabled
                      - log_destination = 'stderr'
                      - logging_collector = on
                      - log_directory = 'pg_log'
                      - log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
                      - log_file_mode = 0600
                      - log_truncate_on_rotation = on
                      - log_rotation_age = 1d
                      - log_rotation_size = 64MB 
                      - client_min_messages = log
                      - log_min_messages = error
                      - log_min_error_statement = error
                      - log_min_duration_statement = 100
                      - log_checkpoints = on
                      - log_connections = on
                      - log_disconnections = on
                      - log_duration = on
                      - log_error_verbosity = default
                      - log_hostname = on
                      - log_line_prefix = '%t:%r:%u@%d:[%p]: '
                      - log_lock_waits = on
                      - log_statement = mod
                      - log_replication_commands = off
                      - log_temp_files = 0

      - pg_hba.conf:
           - The PostgreSQL access configuration file
           - The options are set in the following scripts:
                - build/docker-entrypoint.sh
                - pg-config/scripts/configure.sh 


******* GENERATE THE BOTTLED WATER CLIENT IMAGE ******************

-> Copy the binaries with the Bottled Water 's PostgreSQL plugin to the folder with the 'Dockerfile.client':
      - They are generated in the volume 'dbbw1' with the names:
           - avro.tar.gz  bottledwater-bin.tar.gz  librdkafka.tar.gz
      - Copying:
           - sudo cp /var/lib/docker/volumes/dbbw1/_data/avro.tar.gz .
           - sudo cp /var/lib/docker/volumes/dbbw1/_data/librdkafka.tar.gz .
           - sudo cp /var/lib/docker/volumes/dbbw1/_data/bottledwater-bin.tar.gz .

-> Generate the image:
      - docker build -f ./Dockerfile.client -t uyjco0/bw-client:01 .



******* USING THE BOTTLED WATER CLIENT IMAGE ******************

-> docker run -d --restart=always --name bwclient1 -e INSTANCE_NAME=bwclient1 -e POSTGRES_HOST=pg1 -e POSTGRES_USER=challenge -e POSTGRES_USER_PASS=challenge -e POSTGRES_DB=challenge -e KAFKA_HOST=kf1 -e SCHEMA_HOST=sr1 uyjco0/bw-client:01:


-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'bwclient1'
      - POSTGRES_HOST: the host 's name where the Master Postgres is running:
           - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Master Postgres container (i.e. 'pg1') 
           - It is not working if it is pointing to the pooling server (instead of the Master Postgres)
      - POSTGRES_PORT: the port where the Master Postgres is listening:
           - Default is 5432
      - POSTGRES_DB: the name of the database to be used
      - POSTGRES_USER: the name of the user with access to the database
      - POSTGRES_USER_PASS: the password for the user with access to the database
      - KAFKA_HOST: the host 's name where an instance of Apache Kafka is running:
           - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Kafka container (i.e. 'kf1')
      - KAFKA_PORT: the port where the Apache Kafka instance is listening:
           - Default is 9092
      - SCHEMA_HOST: the host 's name where an instance of the Confluent Schema Registry is running:
           - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Schema Registry container (i.e. 'sr1')
      - SCHEMA_PORT: the port where the Schema Registry instance is listening:
           - Default is 8081
      - SLOT_NAME: the name of the replication slot to be created in the database:
           - Default is 'bottledwater'



******* OBSERVATIONS ******************

-> How are being generated the binaries with the Bottled Water 's PostgreSQL plugin?:
   - They are generated when the above PostgreSQL image is created: 
        - The binaries are stored in the volume 'dbbw1' with the names:
             - avro.tar.gz  bottledwater-bin.tar.gz  librdkafka.tar.gz

-> The Bottled Water Pluging is being used in order to stream the changes in the PostgresSql database to
   Kafka, i.e. it is working as a Kafka 's Producer that is using the Logical Decoding functionality in
   PostgreSQL in order to produce a Kafka 's message with a change being made in the database

-> When using the Bottled Water Client it is possible to observe the following kind of line logs:
      - '|1464462071.115|FAIL|rdkafka#producer-0| kf1:9092/bootstrap: Receive failed: Disconnected':
           - That is not an error, but a known issue with Apache Kafka (that is not a real error):
                - https://github.com/edenhill/librdkafka/issues/437

-> If it is intended to use the system in production or extend the previous described functionality (i.e. streaming the database) for other
   databases such as MySql and MongoDB, then it is needed to use a tool different than the Bottled Water plugin and client:
      - It is because:
           - It is an early alpha release
           - It is only supporting PostgreSQL
      - An alternative could be:
           - https://github.com/JarvusInnovations/lapidus

-> The current Docker PostgreSQL image is using by default the en_US.utf8 locale:
      - It could be changed by following the instructions at:
           - https://hub.docker.com/_/postgres/
      - It means that is not using the default C Locale:
           - http://www.postgresql.org/docs/9.5/static/locale.html
           - In this case we need to create an index with a special operator class in order to support indexing pattern matching:
                - As the one it is being created for the 'csvs' example table:
                     - 'CREATE INDEX csvs_name_pattern_idx ON csvs(name varchar_pattern_ops)'
                - http://www.postgresql.org/docs/9.5/static/indexes-types.html
                - http://www.postgresql.org/docs/9.5/static/indexes-opclass.html
           - Take care because this index is only supporting 'left anchored' pattern matching queries, for a more flexible solution we can use
             a Trigram Index or Full Text Search:
                - http://dba.stackexchange.com/questions/117403/faster-query-with-pattern-matching-on-multiple-text-fields
                - http://dba.stackexchange.com/questions/2195/how-is-like-implemented/10856#10856
                - http://linuxgazette.net/164/sephton.html

-> In order that the PostgreSQL instances are able to listen by remotes connections:
      - The 'postgresql.conf' must have the line:
           - listen_addresses = '*'
           - It is added automatically by the official Dockerfile:
                - sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample
      - The 'pg_hba.conf' must have the line:
           - host all all 0.0.0.0/0 md5:
                - It is added automatically by the script 'docker-entrypoint.sh' that is run by the official Dockerfile:
                     - echo "host all all 0.0.0.0/0 $authMethod"
