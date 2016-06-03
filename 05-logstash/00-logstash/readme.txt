
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate a Docker LOGSTASH image:
      - Logstash will be used to centralize the logs processing from all the services composing the application:
           - Used as a producer:
                - The logs from all the services are being sent by Logstash to Apache Kafka under the 'logstash' topic
           - Used as a consumer:
                - The logs from some services are being consumed by Logstash from Apache Kafka under the 'logstash' topic 



******* SOURCES ******************

-> The official LOGSTASH image:
      - https://hub.docker.com/_/logstash/



******* NEEDED ******************

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)



******* GENERATE THE LOGSTASH IMAGE *****************

-> docker build -t uyjco0/logstash:01 .



******* USING THE logstash IMAGE *****************


 +++++++++ Used as a producer +++++++++


-> docker run -d --restart=always --name lstash1 -e INSTANCE_NAME=lstash1 -e BOOTSTRAP_SERVERS="kf1:9092" -v vol_name1:/var/log/postgres1:rw -v vol_name2:/var/log/postgres2:rw -v vol_name3:/var/log/pooling1:rw -v vol_name4:/var/log/zookeeper1:rw -v vol_name5:/var/log/kafka1:rw -v vol_name6:/var/log/node-web1:rw -v vol_name7:/var/log/node-worker1:rw -v some_host_path/logstash-producer.conf:/etc/logstash/logstash-producer.conf uyjco0/logstash:01 logstash --config /etc/logstash/logstash-producer.conf --allow-env

-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'lstash1'
      - BOOTSTRAP_SERVERS: the hostnames and ports where the Apache Kafka brokers are running 
           - Default is "kf1:9092"

-> Volumes mapping:
      - '-v vol_name1:/var/log/postgres1:rw' is mounting some existing named volume (i.e. 'vol_name1') to the container folder '/var/log/postgres1':
           - The existing named volume has the log files of the Master PostgreSQL server
           - The Logstash 's configuration file 'logstash.conf' is using the container folder '/var/log/postgres1' for the input plugin 's configuration
      - '-v vol_name2:/var/log/postgres2:rw' is mounting some existing named volume (i.e. 'vol_name2') to the container folder '/var/log/postgres2':
           - The existing named volume has the log files of the Slave PostgreSQL server
           - The Logstash 's configuration file 'logstash.conf' is using the container folder '/var/log/postgres2' for the input plugin 's configuration
      - '-v vol_name3:/var/log/pooling1:rw' is mounting some existing named volume (i.e. 'vol_name3') to the container folder '/var/log/pooling1':
           - The existing named volume has the log files of the Pooling service
           - The Logstash 's configuration file 'logstash.conf' is using the container folder '/var/log/pooling1' for the input plugin 's configuration
      - '-v vol_name4:/var/log/zookeeper1:rw' is mounting some existing named volume (i.e. 'vol_name4') to the container folder '/var/log/zookeeper1':
           - The existing named volume has the log files of the Apache Zookeeper server
           - The Logstash 's configuration file 'logstash.conf' is using the container folder '/var/log/zookeeper1' for the input plugin 's configuration
      - '-v vol_name5:/var/log/kafka1:rw' is mounting some existing named volume (i.e. 'vol_name5') to the container folder '/var/log/kafka1':
           - The existing named volume has the log files of the Apache Kafka server
           - The Logstash 's configuration file 'logstash.conf' is using the container folder '/var/log/kafka1' for the input plugin 's configuration
      - '-v vol_name6:/var/log/node-web1:rw' is mounting some existing named volume (i.e. 'vol_name6') to the container folder '/var/log/node-web1':
           - The existing named volume has the log files of the node-web cluster
           - The Logstash 's configuration file 'logstash.conf' is using the container folder '/var/log/node-web1' for the input plugin 's configuration
      - '-v vol_name7:/var/log/node-worker1:rw' is mounting some existing named volume (i.e. 'vol_name7') to the container folder '/var/log/node-worker1':
           - The existing named volume has the log files of the node-worker cluster
           - The Logstash 's configuration file 'logstash.conf' is using the container folder '/var/log/node-worker1' for the input plugin 's configuration
      - '-v some_host_path/logstash.conf:/etc/logstash/logstash.conf' is mounting the configuration file 'logstash.conf' in the local host to the container
        '/etc/logstash/logstash.conf':
           - This configuration file is declared in the flag '--config' when running the container


 +++++++++ Used as a consumer +++++++++


-> docker run -d --restart=always --name lstash2 -e INSTANCE_NAME=lstash2 -e BOOTSTRAP_SERVERS="kf1:9092" -v some_host_path/logstash-consumer.conf:/etc/logstash/logstash-consumer.conf uyjco0/logstash:01 logstash --config /etc/logstash/logstash-consumer.conf --allow-env

-> Available '-e' flags for running the container:ddd
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'lstash1'
      - BOOTSTRAP_SERVERS: the hostnames and ports where the Apache Kafka brokers are running
           - Default is "kf1:9092"



******* CONFIG FILES USED IN THE LOGSTASH IMAGE ******************

-> Producer configuration:
      - logstash-producer.conf:
           - It is the configuration file for 'Logstash' when used as an Apache Kafka 's producer:
                - https://www.elastic.co/products/logstash
           - It is using the BOOTSTRP_SERVERS variable (in the 'Apache Kafka' output plugin):
                - In order to make this variable visible to Logstash, we need to start Logstash with the flag '--allow-env':
                     - Source:
                          - https://www.elastic.co/guide/en/logstash/current/environment-variables.html

-> Consumer configuration:
      - logstash-consumer.conf:
           - It is the configuration file for 'Logstash' when used as an Apache Kafka 's consumer:
           It is using the BOOTSTRP_SERVERS variable (in the 'Apache Kafka' output plugin):
                - In order to make this variable visible to Logstash, we need to start Logstash with the flag '--allow-env'



******* OBSERVATIONS ******************

-> With the 2.3 version of Logstash:
      - The version of the 'Apache Kafka' output plugin is 2.0.5:
           - In order to work with a higher version it is needed to upgrade the plugin:
                - The current version is 4.0.1
                - The Dockerfile has a RUN attribute for that
      - The version of the 'Apache Kafka' input plugin is 2.0.8:
           - In order to work with a higher version it is needed to upgrade the plugin:
                - The current version is 4.0.0:
                     - The central documentation (https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html) about the options is outdated:
                          - For example:
                               - 'zk_connect' is not used anymore, instead it is used 'bootstrap_servers'
                               - 'topic_id' is not used anymore, instead it is used 'topics' (an array)
                          - We can see the real options at:
                               - https://github.com/logstash-plugins/logstash-input-kafka/blob/master/lib/logstash/inputs/kafka.rb
                - The Dockerfile has a RUN attribute for that

-> Important documentation sources for Logstash:
      - https://www.elastic.co/guide/en/logstash/current/index.html
           - The most important:
                - Input plugins: https://www.elastic.co/guide/en/logstash/current/input-plugins.html 
                - Filter plugins: https://www.elastic.co/guide/en/logstash/current/filter-plugins.html
                - Output plugins: https://www.elastic.co/guide/en/logstash/current/output-plugins.html
                - Codec plugins: https://www.elastic.co/guide/en/logstash/current/codec-plugins.html
                - Event dependent configuration: https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html
                - Configuration examples: https://www.elastic.co/guide/en/logstash/current/config-examples.html
              
-> Using Logstash with PostgreSQL:
      - Using the 'sincedb_path':
           - It is a file that is storing the last position that Logstash read from the log files:
                - http://stackoverflow.com/questions/29573097/logstash-file-input-sincedb-path/30035760#30035760
                - http://stackoverflow.com/questions/27985012/understanding-sincedb-files-from-logstash-file-input
      - PostgreSQL log format:
           - http://www.postgresql.org/docs/9.5/static/runtime-config-logging.html:
                - log_line_prefix
           - http://www.postgresql.org/message-id/fiooqf$1skq$1@news.hub.org
      - Multi-line logs:
           - https://discuss.elastic.co/t/grok-filter-for-multi-line-postgresql-log/39854
