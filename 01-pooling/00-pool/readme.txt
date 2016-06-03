
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate a Docker POOLING SERVER image to be used with the Docker POSTGRESQL images:
      - The image is using a 'PgBouncer' server that is redirecting all the incoming calls to a 'pgpool' server that is also running in the image:
         - Both processes are controlled by 'supervisord'


****** SOURCES ******************

-> It is custom code


******* NEEDED ******************

> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)

-> Creating a named volume:
      - Delete the volume if it already exists (if it is needed):
           - docker volume rm dpool1
      - Creating the needed volumes:
           - docker volume create --name dbpool1
      - We can see where is the physical folder in the host for the volume with:
           - docker volume inspect dbpool1


******* GENERATE THE POOLING IMAGE ******************

-> The command to build the image from the Dockerfile is:
      - docker build -t uyjco0/pooling:01 .


******* USING THE POOLING IMAGE ******************

-> docker run -d --restart=always --name pool1 -e INSTANCE_NAME=pool1 -v dbpool1:/var/log/pooling:rw uyjco0/pooling:01

-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'pool1'


******* CONFIG FILES USED IN THE POOLING IMAGE ******************

-> pgbouncer.ini:
      - It is the configuration file for 'PgBouncer':
           - https://pgbouncer.github.io/config.html
      - In the section '[databases]':
           - Here it is not pointing to a database, but to the 'pgpool' service:
                - '* = host=pool1 port=2000'
                - It means that 'PgBouncer' is used in the front as a Connection Pooler, then it connects to 'pgpool', which is used for Load Balancing 
                  only (taking advantage of the built-in streaming replication in the PostgreSql servers)
      - In the section '[pgbouncer]':
           - 'listen_port=5426':
                - The same that the default PostgreSQL server in order to avoid problems with the clients that are expecting that
           - 'listen_addr = *':
                - 'PgBouncer' will be listening on all the IP addresses
           - 'pool_mode = transaction':
                - The connection to the PostgreSQL server being used by a client is released back to pool after transaction finishes:
                     - It is most efficient that using the 'session' mode, but when using 'transaction' the application need to be aware that there are some non working features:
                          - This non working features are: Cursors and Prepared Statements
                          - https://wiki.postgresql.org/wiki/PgBouncer
                - It is something that 'pgpool' does not have
           - 'auth_type':
                - How the users are authenticated against the PostgreSQL server:
                     - If 'md5' is set, then the file declared in 'auth_file' may contain both MD5-encrypted or plain-text passwords for this users 
           - 'max_client_conn':
                - It is the maximum number of client connections allowed to connect to 'PgBouncer' without being rejected:
                     - i.e. it is the maximum amount of client connections that will be pooled by 'PgBouncer':
                          - It is not the number of simultaneously active connections that are allowed to the database servers
                - It must support all the concurrent database connections coming from all the 'node-web' (write requests) and the 'node-worker' (read requests) running instances
           - 'default_pool_size' , 'reserve_pool_size':
                - 'default_pool_size' + 'reserve_pool_size' is the amount of simultaneously active connections per user/database pair that we can have to 
                  a PostgreSQL server in any moment
                     - For one pair {user, database}, 1 PostgreSQL server, and not cancelling queries:
                          0. One pair {user, database} means that all the connections are being made to the same database using the same user
                          1. Here we leave the 'max_pool' parameter in the configuration file 'pgpool.conf' to its default value 1 
                          2. 'default_pool_size' + 'reserve_pool_size' must be equal to the parameter 'num_init_children' in the configuration file 'pgpool.conf':
                                - 'num_init_children' is the number of simultaneously active connections we can have to the individual PostgreSQL server in any moment
                          3. 'num_init_children' <= (max_connections - superuser_reserved_connections):
                                - Where 'max_connections' is the parameter in the configuration file 'postgresql.conf':
                                     - It controls the amount of allowed simultaneously active connections to the PostgreSQL server
                                     - We need to reserve some extra connections for administrative purposes (i.e. the 'superuser_reserved_connections')
                                     - Source:
                                          - http://www.pgpool.net/mediawiki/index.php/Relationship_between_max_pool,_num_init_children,_and_max_connections
                                     - Observation if we want to cancel a query from the client (i.e. for example using 'pg_cancel_backend') then we need to double
                                       the connections:
                                          - http://www.pgpool.net/docs/latest/pgpool-en.html
                     - For N pairs {user, database}, 1 PostgreSQL server, and not cancelling queries:
                          1. We need to set in the configuration file 'pgpool.conf':
                                - 'max_pool = N'
                          2. In this case 'default_pool_size' + 'reserve_pool_size' must be equal to the parameter 'num_init_children' in the configuration file 'pgpool.conf':
                                - 'max_pool'*'num_init_children' is the number of simultaneously active connections we can have to the individual PostgreSQL server in any moment
                          3. 'max_pool'*'num_init_children' <= (max_connections - superuser_reserved_connections)
                     - For N pairs {user, database}, R PostgreSQL servers in Master/Slave mode, and not cancelling queries:
                          1. We need to set in the configuration file 'pgpool.conf':
                                - 'max_pool = N'
                          2. When there are R servers in Master/Slave mode (i.e. 1 Master and R-1 slaves), then 'pgpool' will be opening 'max_pool'*'num_init_children' to each server:
                                - http://www.sraoss.jp/pipermail/pgpool-general/2012-January/000186.html
                                - It means that 'max_pool'*'num_init_children'*R is the total number of simultaneously active connections we are having to the PostgreSQL servers:
                                     - Still 'max_pool'*'num_init_children' is the number of simultaneously active connections we can have to each individual PostgreSQL server in any moment
                                - In this case we need that 'default_pool_size' + 'reserve_pool_size' = R*'num_init_children'
                          3. 'max_pool'*'num_init_children' <= (max_connections - superuser_reserved_connections) in each PostgreSQL server

-> haproxy.cfg:
      - The configuration file for 'HAProxy':
           - http://www.haproxy.org
      - The 'HAProxy' service is used in order to give enough ephemeral ports to the 'node-worker' instances:
           - The 'HAProxy' is listening in several ports and fowarding all the requests to the 'PgBouncer' service:
                - The 'HAProxy' is listening in the ports:
                     - 5427 5428 5429 5430 5431 5432:
                          - The port 5432 is the default PostgreSQL port, so this port should not be used with the
                            'node-worker' instances:
                               - It will be used for all the services that are expecting the default PostgreSQL service:
                                    - As for example the 'node-web' instances
                          - So the 'web-worker' instances have available 5 different ports to connect:
                               - When configuring the Linux OS system, the amount of available ephemeral ports shuld be set as follow:
                                    - In the file '/etc/sysctl.conf' change/add the following line:
                                         - net.ipv4.ip_local_port_range = 5433 65535
                                              - It gives a range of 60.102 available ephemeral ports for each port that the 'HAProxy' is listening
                                                   - Then, if the Linux OS in the physical machine where a 'node-worker' instance is running, it is configured with the same setting:
                                                        - This single 'node-worker' instance is able to have 5*60102 = 300.510 concurrent connections (60.102 to each of the available
                                                          ports in the 'HAProxy' service)
                                    - See more at:
                                         - 'node-scalable/03-node/02-node-worker/readme.txt'    
      - The parameters:
           - 'maxconn 300000':
                - It must match the 'PgBouncer' 's parameter 'max_client_conn' (see above)
                - It is also needed to configure the Linux OS as follows:
                     - In the file '/etc/sysctl.conf' change/add the following line:
                          - fs.file-max = 700000
                            fs.nr_open = 700000
                            net.ipv4.netfilter.ip_conntrack_max = 720896
                            net.nf_conntrack_max = 720896

                            net.core.rmem_max = 16777216
                            net.core.wmem_max = 16777216
                            net.core.rmem_default = 16777216
                            net.core.wmem_default = 16777216
                            net.ipv4.tcp_rmem = 4096 4096 16777216
                            net.ipv4.tcp_wmem = 4096 4096 16777216
                            net.core.netdev_max_backlog = 50000
                            net.ipv4.tcp_max_syn_backlog = 30000
                            net.ipv4.tcp_max_tw_buckets = 2000000
                            net.ipv4.tcp_tw_reuse = 1
                            net.ipv4.tcp_fin_timeout = 10
                            net.ipv4.tcp_keepalive_time = 300
                            net.ipv4.tcp_keepalive_probes = 5
                            net.ipv4.tcp_keepalive_intvl = 15
                            net.ipv4.tcp_slow_start_after_idle = 0

		            vm.swappiness = 10
                            vm.dirty_ratio = 60
                            vm.dirty_background_ratio = 2

                     - In the file '/etc/security/limits.conf' change/add the following lines:
                          - root soft nofile 700000
                            root hard nofile 700000
                            * soft nofile 700000
                            * hard nofile 700000
           - 'timeout client 1m' and 'timeout server 1m':
                - Give it enough width in order to support unexpected loads, otherwise a lot of
                  connections will be rejected 
                                 

-> users.txt:
      - It is the file declared in the 'auth_file' parameter in the 'pgbouncer.ini' configuration file
      - It has one of the following formats:
           - "user" "user_password"
           - "user" "user_password_md5hash"

-> pgpool.conf:
      - It is the configuration file for 'pgpool':
           - http://www.pgpool.net/docs/latest/pgpool-en.html
      - The most important parameters in order to configure 'pgpool' for Load Balancing using the PostgreSQL Master/Slave streaming replication:
           - 'listen_addresses = '*'':
                - 'pgpool' will be listening on all the IP addresses
           - 'port = 2000':
                - It is the port that the clients will be using, as 'pgpool' is behind 'PgBouncer' we can set it:
                     - But if 'pgpool' is set in front of the clients, then it is better to set the default PostgreSQL server in order to avoid problems with the clients that are expecting that
           - Backend servers:
                - For each Master/Slave server we need to set a backend server in the configuration file:
                     - For each backend server we need to set the following parameters:
                          - 'backend_hostnamei', 'backend_porti', 'backend_weighti' and 'backend_flagi':
                               - Where 'i' is the number of the backend server:
                                    - The master should be set with i=0 (i.e. the master is 'backend_hostnamei')
                          - For each backend server I'm setting the parameter 'backend_hostnamei' to the hostname given by 'Weave'
                          - The slaves backends are having more 'backend_weighti' than the master:
                              - 'pgpool' in mandatory way is sending all the write queries to the master, and it is using a random Round Robin using the weights to send the read queries:
                                   - I'm setting more weight in the slaves because I don't want read queries in the Master
                          - Configuring failover:
                               - When failover is not managed, then we need to set 'backend_flagi' to 'DISALLOW_TO_FAILOVER', and it is not needed to set the parameter 'backend_data_directoryi'
           - Load balancing with a Master/Slave setting:
                - 'replication_mode = off'
                - 'load_balance_mode = on'
                - 'master_slave_mode = on'
                - 'master_slave_sub_mode = 'stream''
                - 'parallel_mode = off'
                - 'database_redirect_preference_list = 'challenge:standby'':
                     - It means we want the SELECT queries (i.e. the read queries) to be redirected to the standby nodes (then are not going to the primary -i.e. the master-):
                          - http://www.pgpool.net/docs/latest/pgpool-en.html
                - Optionals:
                     - 'delay_threshold ', 'sr_check_period', 'black_function_list' and 'white_function_list':
                          - Here I'm setting:
                               'sr_check_period = 10' and 'delay_threshold = 10000000':
                                  - https://github.com/rdio/pgpool2/blob/master/pgpool.conf.sample-stream
                                  - http://dba.stackexchange.com/questions/119941/pgpool-load-balancing-is-sending-all-queries-only-to-master
           - Other needed paramenters:
                - 'num_init_children = 25'
                - 'max_pool = 1'
                - 'child_life_time = 1000'
                - 'child_max_connections = 1000':
                     - The number of times a pooled connection can be used before it terminates and restarts. It is there to recycle connection threads and stop memory leaks
                - 'enable_pool_hba = on'
                - 'pool_passwd = 'pool_passwd''
                - 'sr_check_user = 'challenge'' and 'sr_check_password = 'challenge'':
                     - If the user and password to connect to the database is not set, then when 'pgpool' will fail when it is starting and trying to determine which one is the
                       primary server
                - 'connection_cache = on'
                - 'reset_query_list = 'ABORT; DISCARD ALL'
                - 'log_connections = off', 'log_hostname = off', 'log_statement = off' and 'log_per_node_statement = off':
                     - For performance reasons
                - 'debug_level = 0'
           - Other optionals:
                - The 'HEALTH CHECK' parameters 
                - The failover configuration

-> pool_hba.conf:
      - It is used to define the settings for client authentification:
           - Here the same the the 'pg_hba.conf' for the PostgreSQL servers
      - If it is using MD5 authentication, you need to register the names and passwords in the 'pool_passwd' file    

-> pool_passwd:
      - The format is:
           - user:md5_password_hash
      - In order to generate the 'md5_password_hash':
           - We need to connect to the database and issue the following command:
                - 'select passwd from pg_shadow where usename = 'username''
                     - It is needed to do that because the official instructions (at: http://www.pgpool.net/docs/latest/pgpool-en.html#md5 ) are wrong:
                          - http://stackoverflow.com/questions/13179628/pgpool-ii-authentication-failure

-> supervisor.conf:
      - The configuration file for the 'supervisord' system to control the 'PgBouncer' and 'pgpool' services:
           - http://supervisord.org 
