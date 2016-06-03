
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>




******* GOAL ******************

-> Here are the instructions to generate a cluster of 'worker' nodes distributed on the CPUs of a single host:
      - Each 'worker' node is a Node.js server
      - The number of 'web' workers to be configured in 'supervisor.conf' depends on the single host 's number of CPUs
      - The 'worker' nodes are started by 'supervisor'



******* SOURCES ******************

-> It is custom code using the official NODE image:
      - https://github.com/nodejs/docker-node/tree/10940306b6ae14f9d2fb0d9a7327e768eadc039a/6.1



******* NEEDED ******************

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)

-> Creating a named volume:
      - Delete the volume if it already exists (if it is needed)::
           - docker volume rm dbworkerg1
      - Creating the needed volumes:
           - docker volume create --name dbworkerg1
      - We can see where is the physical folder for the volume with:
           - docker volume inspect dbworkerg1



******* GENERATE THE NODE-WORKER IMAGE *****************

-> docker build -t uyjco0/node-worker:01 .



******* USING THE NODE-WORKER IMAGE *****************

-> docker run -d --restart=always --name workerg1 -e INSTANCE_NAME=workerg1 -e KAFKA_REST_PROXY_HOST=rp1 -e KAFKA_REST_PROXY_PORT=8082 -e KAFKA_TOPIC_NAME=csvs -e KAFKA_CONSUMER_GROUP_NAME=cg_csv -e KAFKA_FROM_BEGINNING=1 -v some_local_path:/opt/nodeapp:rw -v dbworkerg1:/var/log/nodeapp:rw uyjco0/node-worker:01

-> Available '-e' flags for running the container:
           - Additional variables that can be specified using the '-e' flag:
                - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
                     - Default is 'workerg1'
                - DB_PORT: the port where the database will be listening
                     - It could be a list with the following format:
                          - DB_PORT_1,DB_PORT_2
                               - The list is used to avoid the port exahustion problem, so avoid to use in it the default PostgreSQL port (5432):
                                    - See more at:
                                         - node-scalable/01-pooling/00-pool/readme.txt
                     - Default is '5427,5428,5429,5430,5431'
                - DB_HOST: The hostname where the database or a pooling service is running
                     - It is pointing to the PostgreSql container (i.e. 'pg1') or to the container with the Pooling service for the PostgreSql server (i.e. 'pool1')
                     - Default is 'pool1'
                - DB_DATABASE: The name of the database with the data
                     - Default is 'challenge'
                - DB_USER: The user that has access to the database with the data
                     - Default is 'challenge'
                - DB_PASSWORD: The passord of the user that has access to the database
                     - Default is 'challenge'
		- DB_POOL_SIZE: The pool size being used by the module 'node-postgres':
                     - When using an external pooling solution (as PgBouncer), then the 
                       size should be 1 in order to avoid double-pooling:
                          - Source:
                               - https://github.com/brianc/node-postgres/issues/975
                     - When not using an external pooling solution then could be set to a higher number:
                          - i.e. for example '-e DB_POOL_SIZE=10'
                     - Default is 1
                - MEMORY_PROFILING: if running the memory profiling option or not
                     - Default is 'n'
                - KAFKA_REST_PROXY_HOST: Where is the Confluent Rest Proxy that the worker is using to implement the consumer functionality:
                     - Default is 'rp1'
                - KAFKA_REST_PROXY_PORT: Where is listening the Confluent Rest Proxy that the worker is using
                     - Default is 8082
                - KAFKA_TOPIC_NAME: The name of the topic to which the worker is subscribing
                     - Default is 'csvs'
                - KAFKA_CONSUMER_GROUP_NAME: The name of the Consumer Group to which the worker belongs
                     - Default is 'cg_csv'
                          - If all the workers are not using the same Consumer Group name , then the same message could be consumed several times for different workers
                          - For the same Consumer Group name the maximum amount of workers that could be consuming messages in parallel is set by the Apache Kafka parameter 'KAFKA_num.partitions'
                - KAFKA_FROM_BEGINNING: It says from where the worker must start to consume when still there is not a committed offset
                     - Default is 1

-> Volumes mapping:
      - '-v /some_local_path:/opt/nodeapp:rw' is mapping the folder where is the application files (i.e. 'some_local_path) to the container volume
      - '-v dbworkerg1:/var/log/nodeapp:rw' is mapping the log directory to the volume



******* CONFIG FILES USED IN THE NODE-WEB IMAGE ******************

-> supervisor.conf:
      - The configuration file for the 'supervisord' system to control the node-worker instances in a single host:
           - http://supervisord.org


-> It is needed configure the Linux OS in order to have enough resources for the needed concurrent connections:
      - The needed concurrent connections are read requests to the database:
           - These connections are being made to the 'Pooling service' (i.e. against its frontend 'PgBouncer'):
                - It is being used as a base the assumption made in 'node-scalable/00-bottledwater-pg/readme.txt':
                     - In each second we have 25 write requests with 10.000 lines each one:
                          - That is generating 25*10.000 = 250.000 read requests to the database each second:
                               - Then it is being used an upper bound of 250.000 concurrent connections
      - In order to enable this amount of concurrent connections in the Linux OS it is need:
           1. To modify the configuration file '/etc/sysctl.conf':
                 - It is need a lot of file descriptors (the used for the concurrent connection plus the others used by the OS and the application):
                      - It is added an upper bound of 1.000.000 with the following lines:
                           - fs.file-max = 1000000
                             fs.nr_open = 1000000
                 - RAM usage for the connections:
                        - net.core.rmem_max = 16777216
                          net.core.wmem_max = 16777216
                          net.core.rmem_default = 16777216
                          net.core.wmem_default = 16777216
                          net.ipv4.tcp_rmem = 4096 4096 16777216 
                          net.ipv4.tcp_wmem = 4096 4096 16777216
                 - Increase the port range for ephemeral ports:
                      - net.ipv4.ip_local_port_range = 5433 65535
                           - It gives 60.102 ephemeral ports
                           - It means that it is not possible to have server software that attempts to bind to a port above 5432
                      - The 'node-worker' instances are connecting to an 'HAProxy' service with 5 available ports:
                           - Then a single 'node-worker' instance is able to have 5*60102 = 300.510 concurrent connections:
                                - 300.510 > 250.000 estimated concurrent connections
                                - The 'node-worker' will be able to make 60.102 concurrent connections  to each of the available 
                                  ports in the 'HAProxy' service:
                                     - See more at:
                                          - 'node-scalable/01-pooling/00-pool/readme.txt'
                 - Extra TCP settings:
                      - net.core.netdev_max_backlog = 50000
                        net.ipv4.tcp_max_syn_backlog = 30000
                        net.ipv4.tcp_max_tw_buckets = 2000000
                        net.ipv4.tcp_tw_reuse = 1
                        net.ipv4.tcp_fin_timeout = 10
                        net.ipv4.tcp_keepalive_time = 300
                        net.ipv4.tcp_keepalive_probes = 5
                        net.ipv4.tcp_keepalive_intvl = 15
                        net.ipv4.tcp_slow_start_after_idle = 0
                 - Increase the size for the NAT ip connection tracking table:
                      - net.ipv4.netfilter.ip_conntrack_max = 1048576
                        net.nf_conntrack_max = 1048576
                 - Discourages kernel from swapping memory to disk:
                      - vm.swappiness = 10
                        vm.dirty_ratio = 60
                        vm.dirty_background_ratio = 2 
           2. Increase the session limits according the above parameter 'fs.file-max':
                 - Add the file '/etc/security/limits.conf' with the following lines:
                      -   root soft nofile 1000000
                          root hard nofile 1000000
                          * soft nofile 1000000
                          * hard nofile 1000000
           3. The 'HAProxy' s parameter 'maxconn' should be equal or greater than the the maximum estimated amount of concurrent connections to the
              database:
                 - It must support all the concurrent database connections coming from all the 'node-web' (write requests) and the 'node-worker' (read requests)
                   running instances
                 - See at:
                      - 'node-scalable/01-pooling/00-pool/haproxy.cfg'
                           - 300.000 > 250.000 
           4. The 'PgBouncer' s parameter 'max_client_conn' should be equal or greater than the maximum estimated amount of concurrent connections to
              the database:
                 - It must support all the concurrent database connections coming from all the 'node-web' (write requests) and the 'node-worker' (read requests) 
                   running instances
                 - See at:
                      - 'node-scalable/01-pooling/00-pool/pgbouncer.ini'
                           - 300.000 > 250.000
           5. Enough RAM in order to handle all these concurrent connections 
