
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>




******* GOAL ******************

-> Build a demo of a scalable and distributed application:
      - The application is able to scale:
           - Verticaly:
                - By improving the physical host features:
                     - I.e. more CPUs, more RAM, etc.:
                          - In fact it is the suggested for the host
                            where is running the Master PostgreSQL server
           - Horizontally:
                - By adding more physical hosts:
                     - It is true for all the components except
                       the Master PostgreSQL server (i.e. in a
                       Master/Slave configuration there is only
                       one master at the same time):
                          - In order to have horizontal scalability
                            it is needed to implement sharding

-> How to start running the application?:
      - node-scalable/06-test/readme.txt



******* ARCHITECTURE ******************

-> The application 's conceptual architecture is composed by the following main blocks:
      1. 'Web services' and 'workers':
            1.1. The Web services are HTTP enabled servers in charge of
                 being the application 's client frontend (i.e. receiving
                 their requests and sending back the responses)
            1.2. The workers are the servers in charge of running
                 different background tasks
            1.3. For a theoretical underpinning see 'Microservices' at:
                    - https://github.com/mfornos/awesome-microservices
      2. 'Load balancer':
            - It is in charge of balancing the client requests between
              the available 'Web services' 
      3. 'Message bus':
            - The 'Web services' and 'workers' are communicating with
              each other through the message bus
      4. 'Databases':
            - They are in charge of storing data in some format that
              is useful for the application:
                 - For example, here could be used 'Elasticsearch' in
                   order to provide text search for the application
      5. 'Pooling':
            - They are between the 'Web services'/'Workers' and the 
              'Databases':
                 - They are offering Connection Re-using, Load Balancing
                   between the database instances, and other useful features

-> The architecture is shown in the following attached graphical schema:
      - 'node-scalable/07-docs/architecture_01.jpg'
          


******* ARCHITECTURE IMPLEMENTATION ******************
          
-> The conceptual architecture is instantiated as described in the following
   attached graphical diagrams:
      1. 'node-scalable/07-docs/architecture_02.jpg':
            - It is showing the software choices that were made in order
              to implement the architecture:
                 - Alternative choices:
                      - For the 'Message bus':
                           - RabbitMQ:
                                - https://www.rabbitmq.com
                      - For the 'Workers':
                           - Celery:
                                - http://www.celeryproject.org
                                - Here a 'Worker' is a 'Task' implemented in
                                  Python using some of the following concurrent
                                  alternatives:
                                     - '-P prefork'
                                     - '-P threads'
                                     - '-P eventlet'
                      - For the 'Databases':
                           - If it is needed 'write and read' scaling for PostgreSQL:
                                - It is possible to use 'Citus Data':
                                     - https://www.citusdata.com
                                     - It is an Open Source extension to PostgreSQL
                                       that is offering sharding
                           - Using some NoSQL solution as:
                                - Apache Cassandra:
                                     - http://cassandra.apache.org
                                - Redis:
                                     - http://redis.io
                                - Basho solutions:
                                     - http://basho.com/products
                                - Others
                 - Why choosing the Confluent Plataform (over for example RabbitMQ)?:
                      - http://www.confluent.io
                      - In one tool you have a 'Message bus', a "Task queue' and a real-time
                        stream processing framework that is truly distributed (and scalable):
                           - The 'Topics', 'Partitions' and 'Consumer Groups' are a very
                             powerful abstraction with a great deal of flexibility
                           - See more at:
                                - 'Making sense of stream processing':
                                     - From Martin Kleppmann (O'Reilly)
      2. 'node-scalable/07-docs/architecture_03.jpg':
            - It is showing how the sofware choices are mapped to individual
              physical hosts:
                 - The 'Boottledwater client':
                      - https://github.com/confluentinc/bottledwater-pg
                      - It is using the 'Logical Decoding' feature in PostgreSQL
                        in order to produce messages to Apache Kafka with the
                        database changes (it is also called 'Database streaming'):
                           - It has 2 components:
                                a. A PostgreSQL Plugin (i.e. running within the
                                   database)
                                b. A Client that is running as a daemon (i.e.
                                   running as a service external to the database)



******* SOFTWARE USED ******************

-> Docker:
      - https://www.docker.com
      - It is used in order to pack the application components in Docker
        containers

-> Weave:
      - https://www.weave.works
      - It is used in order to provide a Software-Defined Networking
        (SDN) for the Docker containers

-> Supervisor:
      - http://supervisord.org
      - It is used to be able to run more than 1 process in a Docker
        container 

-> PostgreSQL:
      - http://www.postgresql.org 
      - It is used to implmenent the 'Databases' block:
           - Here it is being implemented 'read' scaling by using the
             PostgreSQL 's native 'streaming replication':
                - It has only 1 master in charge of all the writings, 
                  and several slaves replicating the master using 
                  'streaming replication' with 'physical replication
                  slots':
                     - This replication could be configured 'asynchronous'
                       or 'synchronous'
                - In order to avoid performance degradation in the master
                  it is better to have few slaves replicating directly
                  from the master:
                     - i.e. it is better to have most of the slaves 
                       replicating from other slaves (i.e. using
                       'Cascade Replication')
      - The implementation is at:
           - node-scalable/00-bottledwater-pg

-> PgBouncer & Pgpool:
      - https://pgbouncer.github.io
      - http://www.pgpool.net
      - They are used to implement the 'Pooling' block:
           - PgBouncer is the 'Pooling' frontend:
                - It is offering the real pooling service
           - Pgpool is the 'Pooling' backend:
                - It is offering the Load Balancing of the
                  databases
                - Once 'PgBouncer' allows a client to connect
                  to the database, it sends the client to 'Pgpool'
                  which is in charge of the load balancing of the
                  databases
      - The implementation is at:
           - node-scalable/01-pooling

-> Confluent Platform:
      - http://www.confluent.io 
      - It is used to implement the 'Message bus' block  through the following 
        components:
           - Apache Zookeeper
           - Apache Kafka
           - Confluent Schema Registry
           - Confluent Rest Proxy 
      - By choosing the right combination of 'topic/#_partitions' and 'consumer
        groups' we are controlling the the 'Web Services' & 'workers' scalability
        and load balancing between them
      - The implementation is at:
           - node-scalable/02-confluent 

-> Bottled Water Plugin and Client:
      - https://github.com/confluentinc/bottledwater-pg
      - It is used to stream all the changes in the PostgreSQL database to Apache
        Kafka
      - Beware of the following:
           - It is early alpha-quality software:
                - A production ready alternative could be:
                     - https://github.com/JarvusInnovations/lapidus
                          - But it doesn't have integrated an Apache Kafka 's producer:
                               - But it is very easy to add it using the Confluent Rest Proxy
      - The implementation is at:
           - node-scalable/00-bottledwater-pg

-> Node.js:
      - https://nodejs.org/en
      - It is used to provide the base engine for the block composed by the 'Web services' 
        and some of the 'Workers':
           1. The 'Web services' are implemented as a 'node-web' cluster:
                 - The implementation is at:
                      - node-scalable/03-node/01-node-web
                           - It is implementing the Docker container infraestructure for the
                             'Web services'
                      - node-scalable/04-app
                           - The '04-app/nodeapp/lib/web.js' is implementing the 'Web service'
                             functionality:
                                - It is offering to the application 's client to upload CSV
                                  files straight to the PostgreSQL database
           2. Some of the 'Workers are implemented as a 'node-worker' cluster:
                 - The implementation is at:
                      - node-scalable/03-node/02-node-worker
                           - It is implementing the Docker container infraestructure for the
                             some of the 'Workers'
                      - node-scalable/04-app
                           - The '04-app/nodeapp/lib/worker.js' is implementing a particular kind
                             of 'Worker' functionality:
                                - It is subscribed to the Confluent Platform, so each time that 
                                  a change has ocurred in the PostgreSQL database, it runs a
                                  simple task
      - The implementation is at:
           - node-scalable/03-node

-> Logstash:
      - https://www.elastic.co/products/logstash
      - It is used to provide the implementation of the block composed by some of the
        'Workers':
           - It is implementing a particular kind of 'Worker' functionality:
                1. When used as an Apache Kafka 's producer, it is centralizing all the
                   application logs under the topic 'logstash' in the Confluent Platform 
                   (i.e. in the 'Message bus')
                2. When used as an Apache Kafka 's consumer, it is consuming the application
                   logs under the topic 'logstash' in the Confluent Platform
      - The implementation is at:
           - node-scalable/05-logstash

-> HAProxy:
      - http://www.haproxy.org
      - It is providing the application entrypoint for the application 's clients, 
        and also it is providing load balancing between the different 'Web services'
      - For the 'Pooling service' is is providing enough ports in order to support
        the amount of needed concurrent TCP connections to the database
      - The implementation is at:
           - node-scalable/03-node/01-node-web
           - node-scalable/01-pooling/00-pool
                               


******* SUGGESTED INITIAL PHYSICAL HOSTS FOR USING THE APPLICATION ******************


-> 9 physical hosts:
   - 1 physical host:
          - For running the Master PostgreSQL server
               - The configuration for this host is described at:
                    - node-scalable/00-bottledwater-pg/readme.txt
          - 2 physical hosts:
                 - For running 2 Slave PostgreSQL servers
                      - The configuration for this host is described at:
                           - node-scalable/00-bottledwater-pg/readme.txt
                 - Probably the bottleneck is with the read requests:
                      - In this case, start to add more physical hosts running slave
                        PostgreSQL servers:
                           - But using Cascade Replication in order to avoid degrade
                             the master performance
          - 1 physical host:
               - For running the Pooling service
               - 4 cores
               - Enough RAM for all the concurrent connections
          - 1 physical host:
               - For running the Bottledwater client:
                    - As it is an early alpha-quality software:
                         - It could be also a bottleneck because of the breaks:
                              - A production ready alternative could be:
                                   - https://github.com/JarvusInnovations/lapidus
                                        - But it doesn't have integrated an Apache Kafka 's producer:
                                             - But it is very easy to add it using the Confluent Rest Proxy
               - 2 cores
          - 1 physical host:
               - For running a 'node-web' cluster:
               - 4 cores:
                    - i.e. 3 web services and 1 HAProxy
          - 1 physical host:
               - For running a 'node-worker' cluster:
               - 2 cores:
                    - 2 workers
               - Enough RAM for all the concurrent connections
          - 1 physical host:
               - For running the Confluent Platform:
                    - 1 Apache Zookeeper
                    - 1 Apache Kafka
                    - 1 Confluent Schema Registry
                    - 1 Confluent Rest Proxy
               - 4 cores
          - 1 physical host:
               - For running the Logstash workers
               - 4 cores



******* TODO ******************


-> Make smaller the used Docker images

-> Automatize tests and deployment:
      - Using for example:
           - Jenkins:
                - https://jenkins.io

-> Automatize configuration:
      - Using for example:
           - Ansible:
                - https://www.ansible.com/configuration-management
           - Chef:
                - https://www.chef.io/solutions/configuration-management
           - Puppet:
                - https://puppet.com/solutions/configuration-management
           - Saltstack:
                - https://saltstack.com

-> Running the application on DC/OS:
      - https://dcos.io
