
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to start to test the application:
      - And it is also showing how to start and use the application



******* NEEDED ******************

-> Terminator installed:
      - http://gnometerminator.blogspot.com/p/introduction.html
      - It is not mandatory (only a suggestion):
           - In order to test the application it is best to run
             each service interactively in its own terminal


-> Docker installed:
      - https://docs.docker.com/engine/installation/linux/ubuntulinux


-> Weave installed:
      - https://www.weave.works/install-weave-net


-> Machines with enough physical resources and the Linux OS configured
   for high concurrency:
      - For an idea of the physical resources needed:
           - See at the file:
                - 'node-scalable/00-bottledwater-pg/readme.txt'
      - For an idea of the Linux OS configuration:
                - See at the file:
                     - 'node-scalable/03-node/02-node-worker/readme.txt'
                  

-> Unzip the file 'node-scalable.zip':
      - It is creating a folder named 'node-scalable':
           - It has all the application 's source files needed


-> Download (or generate) the following Docker images:
      1.  uyjco0/postgres-bw-plugin:01
             - In order to generate it:
                  - cd node-scalable/00-bottledwater-pg/
                  - make docker-build 
      2.  uyjco0/pooling:01
             - In order to generate it:
                  - cd node-scalable/01-pooling/00-pool/
                  - docker build -t uyjco0/pooling:01 .
      3. uyjco0/confluent-base:01
            - In order to generate it:
                 - cd node-scalable/02-confluent/00-base/
                 - docker build -t uyjco0/confluent-base:01 .
      4.  uyjco0/confluent-zookeeper:01
             - In order to generate it:
                  - cd node-scalable/02-confluent/01-zookeeper/
                  - docker build -t uyjco0/confluent-zookeeper:01 .
      5.  uyjco0/confluent-kafka:01
             - In order to generate it:
                  - cd node-scalable/02-confluent/02-kafka/
                  - docker build -t uyjco0/confluent-kafka:01 .
      6.  uyjco0/confluent-schema:01
             - In order to generate it:
                  - cd node-scalable/02-confluent/03-schema/
                  - docker build -t uyjco0/confluent-schema:01 .
      7.  uyjco0/confluent-rest:01
             - In order to generate it:
                  - cd node-scalable/02-confluent/04-rest/
                  - docker build -t uyjco0/confluent-rest:01 .
      8.  uyjco0/bw-client:01
             - In order to generate it:
                  - cd node-scalable/00-bottledwater-pg/build/
                  - docker build -f ./Dockerfile.client -t uyjco0/bw-client:01 .
      9.  uyjco0/node-base:01
             - In order to generate it:
                  - cd node-scalable/03-node/00-base/
                  - docker build -t uyjco0/node-base:01 .
      10.  uyjco0/node-web:01
             - In order to generate it:
                  - cd node-scalable/03-node/01-node-web/
                  - docker build -t uyjco0/node-web:01 .
      11. uyjco0/node-worker:01
             - In order to generate it:
                  - cd node-scalable/03-node/02-node-worker/
                  - docker build -t uyjco0/node-worker:01 .
      12. uyjco0/logstash:01
             - In order to generate it:
                  - cd node-scalable/05-logstash/00-logstash/
                  - docker build -t uyjco0/logstash:01 .
      13. uyjco0/uyjco0/stest:01
             - In order to generate it:
                  - cd node-scalable/06-test/01-stest/
                  - docker build -t uyjco0/stest:01 .



******* STEPS TO TEST THE APPLICATION ******************

0. Go to the tests folder:
   0.1. cd node-scalable/06-test

1. Run a Master PostgreSQL server:
   1.1. Open a terminal
   1.2. 00-app/01_start_master_pg.sh dbpg1 y [IP_PEER]
           - The IP_PEER argument is optional:
                - It is used when we want to start the server in a  physical host that still doesn't has a
                  running instance of 'Weave', and we want to add this physical host to an existing 'Weave 
                  network' that is composed by several different physical hosts:
                     - Then it is needed to provide the IP address (i.e. IP_PEER) of some physical host 
                       that is already in this 'Weave network':
                - Then IP_PEER is optional if:
                     - The 'Weave network' is only in a single physical host (i.e. the test is run in a single
                       physical host)
                     - The 'Weave network' will be composed by several different physical hosts, but it still
                       doesn't exist, and 'Weave' is being started at the very first physical host that will
                       belong to this 'Weave network'
                - See more at:
                     - https://www.weave.works/docs/net/latest/using-weave
                     - https://www.weave.works/docs/net/latest/using-weave/finding-adding-hosts-dynamically  
                       
   1.3. In order to start the Slave PostgreSQL server wait until the output of the current script is showing:
           - LOG:  redirecting log output to logging collector process
           - Future log output will appear in directory "pg_log"

2. Run a Slave PostgreSQL server (using asynchronous streaming replication with a physical replication slot):
   2.1. Open a terminal
   2.2. 00-app/02_start_slave_pg.sh dbpg2 y [IP_PEER]
   2.3. In order to start the Pooling service wait until the output of the current script is showing:
           - LOG:  redirecting log output to logging collector process
           - Future log output will appear in directory "pg_log"

3. Run the Pooling service:
   3.1. Open a terminal
   3.2. 00-app/03_start_pooling.sh dbpool1 y [IP_PEER]
   3.3. In order to start the Apache Zookeeper server wait until the output of the current script is showing:
           - INFO success: pgbouncer entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
           - INFO success: pgpool entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)

4. Run the Apache Zookeeper server:
   4.1. Open a terminal
   4.2. 00-app/04_start_zookeeper.sh dbzk1lib y dbzk1log y [IP_PEER]
   4.3. In order to start the Apache Kafka server wait until the output of the current script is showing:
           - INFO binding to port 0.0.0.0/0.0.0.0:2181 (org.apache.zookeeper.server.NIOServerCnxnFactory)

5. Run the Apache Kafka server:
   5.1. Open a terminal
   5.2. 00-app/05_start_kafka.sh dbkf1lib y dbkf1log y dbkf1sec y [IP_PEER]
   5.3. In order to start the Confluent Schema Registry service wait until the output of the current script is showing:
           - INFO Monitored broker is now ready (io.confluent.support.metrics.MetricsReporter)
           - INFO Starting metrics collection from monitored broker... (io.confluent.support.metrics.MetricsReporter)
   5.4. Be patient it takes some time to start!

6. Run the Confluent Schema Registry service:
   6.1. Open a terminal
   6.2. 00-app/06_start_schema.sh [IP_PEER]
   6.3. In order to start the Confluent Rest Proxy service wait until the output of the current script is showing:
           - INFO Server started, listening for requests... (io.confluent.kafka.schemaregistry.rest.SchemaRegistryMain:45)

7. Run the Confluent Rest Proxy service:
   7.1. Open a terminal
   7.2. 00-app/07_start_rest.sh [IP_PEER]
   7.3. In order to start the Bottled Water Client wait until the output of the current script is showing:
           - INFO Server started, listening for requests... (io.confluent.kafkarest.KafkaRestMain:38)
   7.4. Be patient it takes some time to start!

8. Run the Bottled Water Client:
   8.1. Open a terminal
   8.2. 00-app/07_start_rest.sh [IP_PEER]
   8.3. In order to start the node-web cluster wait until the output of the current script is showing:
           - INFO:  bottledwater_export: Table public.csvs is keyed by index csvs_id_pk
           - Snapshot complete, streaming changes from ...

9. Run the node-web cluster:
   9.1. Open a terminal
   9.2. 00-app/09_start_nodeweb.sh ../04-app/nodeapp/ dbwebg1 y [IP_PEER]
   9.3. In order to start the node-worker cluster wait until:
           a. The output of the current script is showing:
                 - INFO success: haproxy entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
                 - INFO success: web2 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
                 - INFO success: web1 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
           b. Load some data to the database 's table 'csvs' in order to enable that the Bottled Water Client is creating the topic 'csvs':
                 - Otherwise the workers will be failing when subscribing to the topic in order to consume message (because they are consumers 
                   not producers, so they are no creating the topic, only consuming from it) 
                 - Load some data to the database 's table 'csvs':
                      - Option 1:
                           - eval $(weave env)
                             docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v /home/jcouchet/Desktop/node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 ab 1 16 y http://webg1.weave.local/upload -n 1 -c 1
                      - Option 2:
                           - Generate a small csv file:
                                - node-scalable/06-test/01-stest/stest/create_file.py -f test.csv -l 3
                                     - It is creating a csv file named 'test.csv' with only 3 lines (good to understand what is going on)
                           - Load the 'test.csv' to the database:
                                - Open in the browser a page pointing to the node-web cluster:
                                     - http://localhost/upload:
                                          - It is using 'localhost' assuming that is running in the current machine

10. Run the node-worker cluster:
    10.1. Open a terminal
    10.2. 00-app/10_start_nodeworker.sh ../04-app/nodeapp/ dbwebg1 y [IP_PEER]
    10.3. In order to watch what is happening:
             - docker volume inspect dbworkerg1
                  - It says that the volume is located in the physical host at:
                       - /var/lib/docker/volumes/dbworkerg1/_data
             - ls /var/lib/docker/volumes/dbworkerg1/_data:
                  - It shows that the volume has the files:
                       - 'worker1.log' and 'worker2.log'
             - In order to watch interactively both files:
                  - less /var/lib/docker/volumes/dbworkerg1/_data/worker1.log:
                       - And press SHIFT + F to stream the file
                  - less /var/lib/docker/volumes/dbworkerg1/_data/worker2.log:
                       - And press SHIFT + F to stream the file
             - Load more csv files to the database through http://localhost/upload and watch what is happening in the 'worker1.log' and 'worker2.log' files

11. Run Logstash as a particular kind of 'Worker' that is an Apache Kafka 's producer:
    11.1. Open a terminal
    11.2. 00-app/11_start_logstash_producer.sh y dbpg1 dbpg2 dbpool1 dbzk1log dbkf1log dbwebg1 dbworkerg1 ../05-logstash/00-logstash/logstash-producer.conf [IP_PEER]
    11.3. In order to start Logstash as an Apache Kafka 's consumer wait until the output of the current script is showing:
             - Created topic "logstash".
             - Settings: Default pipeline workers: 8
             - Pipeline main started
    11.4. Be patient it takes some time to start!

12. Run Logstash as a particular kind of 'Worker' that is an Apache Kafka 's consumer:
    12.1. Open a terminal
    12.2. 00-app/12_start_logstash_consumer.sh ../05-logstash/00-logstash/logstash-consumer.conf [IP_PEER]
    12.3. The output of the current script is showing:
             - Settings: Default pipeline workers: 8
             - Pipeline main started
             - We must to see all the log lines in JSON format
    12.4. Be patient it takes some time to start!



******* STEPS TO RUN A STRESS TEST ******************


0. Before to start running the stress tools, check that:
      - The 'HAProxy' s parameter 'maxconnrate' is able to support the HTTP connection rate
           - For example the current value 'maxconnrate = 200' (i.e. assuming at most 50 connections per second) is not able to support the following stress test: 
                - docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v /home/jcouchet/Desktop/node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 ab 5 16 y http://webg1.weave.local/upload -n 50000 -c 1
                     - It is needed a much higher 'maxconnrate' in order to support the above test
           - See more at:
                - 'node-scalable/03-node/01-node-web/haproxy.cfg'
                - 'node-scalable/03-node/01-node-web/readme.txt'
      - The 'PgBouncer's parameter 'max_client_conn' and the companion 'HAProxy' parameter 'maxconn0 is supporting the concurrent amount of
        TCP connections to the database:
           - It must support all the concurrent database connections coming from all the 'node-web'
             (write requests) and the 'node-worker' (read requests) running instances
           - See more at:
                - 'node-scalable/01-pooling/00-pool/pgbouncer.ini'
                - 'node-scalable/01-pooling/00-pool/readme.txt'
      - The Linux OS is configured to support the amount of HTTP connections + TCP connections
        to the database:
           - For example the current parameter 'net.ipv4.ip_local_port_range = 5433 65535' allows to support 60.102 ephemeral ports:
                - So, trying to establish more than this amount of connections in the same physical host to the same PORT will give an error such as:
                     - "error":{"code":"EADDRNOTAVAIL","errno":"EADDRNOTAVAIL","syscall":"connect","address":"10.32.0.3","port":5432}
           - See more at:
                - 'node-scalable/03-node/02-node-worker/readme.txt'


1. Run a stress tool ('ab' or 'wrk'):
   1.1. Open a terminal
   1.2. Running 'ab':
           - There are several way of running it, as is shown in the following examples:
                - eval $(weave env)
                  docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 ab 5 16 y http://webg1.weave.local/upload -n 1 -c 1
                     - The options '5', '16' and 'y' is saying to generate automatically a CVS test file with 5 lines, where each line is using 16 characters for the first name, surname and email domain:
                          - The generated files are stored at 'node-scalable/06-test/01-stest/stest/test_files', and they are:
                               - test.csv
                               - test.txt:
                                    - It is 'test.csv' encoded in the multipart format
                     - The option 'http://webg1.weave.local/upload'
                     - The options '-n 1' and '-c 1' are 'ab' options:
                          -  All the 'ab' parameters are accepted with the exception of:
                                - '-T'
                                - '-H'
                                - '-p'
                                - the target to test
                - eval $(weave env)
                  docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 ab 5 16 y http://webg1.weave.local/upload
                     - It is running 'ab' with the default option '-t 2000'
                - eval $(weave env)
                  docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01
                     - It is generating automatically a CVS test file with 1000 lines,  where each line is using 16 characters for the first name, surname and email domain
                     - It is running 'ab' with the default option '-t 2000'
   1.3. Running 'wrk':
           - There are several way of running it, as is shown in the following examples:
                - eval $(weave env)
                  docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 wrk 5 16 y http://webg1.weave.local:80/upload -t1 -c1 -d1s
                     - Not adding the port (i.e. ':80') gives the following error:
                          - 'Servname not supported for ai_socktype
                     - The options '-t1',  '-c1' and '-d1s' are 'wrk' options:
                          - All the 'wrk' parameters are accepted with the exception of:
                               - '-s'
                               - the target to test
                - eval $(weave env)
                  docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 wrk 5 16 y http://webg1.weave.local:80/upload
                     - It is running 'wrk' with the default options '-t5', '-c25' and '-d600s'
