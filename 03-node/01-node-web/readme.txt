
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>




******* GOAL ******************

-> Here are the instructions to generate a cluster of 'web' nodes distributed on the CPUs of a single host:
      - Each 'web' node is a Node.js HTTP server
      - The number of 'web' workers to be configured in 'haproxy.cfg' and 'supervisor.conf' depends on the single host 's number of CPUs
      - The 'web' nodes are started by 'supervisor' and load balanced by 'haproxy'



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
           - docker volume rm dbwebg1
      - Creating the needed volumes:
           - docker volume create --name dbwebg1
      - We can see where is the physical folder for the volume with:
           - docker volume inspect dbwebg1



******* GENERATE THE NODE-WEB IMAGE *****************

-> docker build -t uyjco0/node-web:01 .



******* USING THE NODE-WEB IMAGE *****************

-> docker run -d --restart=always --name webg1 -e INSTANCE_NAME=webg1 -e PORT=80 -p 80:80 -v some_local_path:/opt/nodeapp:rw -v dbwebg1:/var/log/nodeapp:rw uyjco0/node-web:01

-> Available '-e' flags for running the container:
           - Additional variables that can be specified using the '-e' flag:
                - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
                     - Default is 'webg1'
                - PORT: the port where the HTTP server will be listening
                     - In this case the flag '-p 3000:3000' must be changed to:
                          - '-p SOME_PORT:PORT'
                     - Default is 3000
                - DB_PORT: the ports where the database will be listening:
                     - It could be a list with the following format:
                          - DB_PORT_1,DB_PORT_2
                     - Default is 5432
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

-> Volumes mapping:
      - '-v /some_local_path:/opt/nodeapp:rw' is mapping the folder where is the application files (i.e. 'some_local_path) to the container volume
      - '-v dbwebg1:/var/log/nodeapp:rw' is mapping the log directory to the volume



******* CONFIG FILES USED IN THE NODE-WEB IMAGE ******************

-> haproxy.cfg:
      - It is the configuration file for 'HAProxy':
           - http://www.haproxy.org
           - Some extra material:
                - https://serversforhackers.com/load-balancing-with-haproxy
                - http://kvz.io/blog/2010/08/11/haproxy-logging
                - http://stackoverflow.com/questions/8750518/difference-between-global-maxconn-and-server-maxconn-haproxy      
      - The 'HAProxy' 's parameter 'maxconnrate' sets the maximum number of connections per second to each 'Web service'
        (i.e. to each 'node-web'):
           - It is also possible to use the parameter 'maxconn'
           - It should be equal or greater than the maximum number of estimated connections per second:
                - The estimated is 25 HTTP connections per second:
                     - 200 > 25
                - The setting should match with the Linux OS configured resources:
                     - See below

-> supervisor.conf:
      - The configuration file for the 'supervisord' system to control the node-web instances in a single host:
           - http://supervisord.org
      - Observation regards starting 'HAProxy':
           - The start command has a delay of 5 seconds (i.e. 'sleep 5') in order to give enough time to start the 
             node-web instances

-> It is needed configure the Linux OS in order to have enough resources for the needed concurrent connections:
      - The amount of needed concurrent connections is determined by:
           - Concurrent HTTP connections:
                - It is defined in the 'haproxy.cfg':
                     - In this file there is much more than the really needed:
                          - The estimation is having 25 HTTP connections per second
           - Concurrent TCP connections to the database:
                - Each HTTP connection is doing a TCP connection to the database:
                     - So the estimated is having 25 TCP connections to the database per second
      - The maximum amount of concurrent connections per second is 50:
           - A much smaller number than the needed by the 'node-worker' machine:
                - In order to see how to configure the Linux OS for high concurrency:
                     - 'node-scalable/02-node-worker/readme.txt'
