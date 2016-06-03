

******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate Docker Confluent KAFKA image



******* SOURCES ******************

-> It is reusing (but modified) code from:
      - https://github.com/confluentinc/docker-images



******* NEEDED ******************

-> When starting the Confluent system, the Kafka containers are started second (the Zookeeper containers are started first)


-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)

-> Creating a named volume:
      - Delete the volume if it already exists (if it is needed)::
           - docker volume rm dbkf1lib
           - docker volume rm dbkf1log
           - docker volume rm dbkf1sec
      - Creating the needed volumes:
           - docker volume create --name dbkf1lib
           - docker volume create --name dbkf1log
           - docker volume create --name dbkf1sec
      - We can see where is the physical folder for the volume with:
           - docker volume inspect dbkf1lib



******* GENERATE THE CONFLUENT KAFKA IMAGE ******************

-> docker build -t uyjco0/confluent-kafka:01 .



******* USING THE CONFLUENT KAFKA IMAGE ******************

-> docker run -d --restart=always --name kf1 -e INSTANCE_NAME=kf1 -e KAFKA_BROKER_ID=1 -e KAFKA_ZOOKEEPER_CONNECT=zk1:2181 -e KAFKA_advertised.host.name=kf1.weave.local -e KAFKA_advertised.port=9092 -e KAFKA_num.partitions=60 -p 9092:9092 -v dbkf1lib:/var/lib/kafka:rw -v dbkf1log:/var/log/kafka:rw -v dbkf1sec:/etc/security:rw uyjco0/custom_confluent_kafka:01

-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'kf1'
      - KAFKA_{kafka_configuration_parameter}:
           - It is possible to add any Zookeeper configuration parameter:
                - They are defined at: http://kafka.apache.org/documentation.html#configuration
                     - As for example: 
                          - The option '-e KAFKA_ZOOKEEPER_CONNECT=zk1:2181' is making reference to the Zookeeper server started before:
                               If using 'weave networking' it will be the same that the INSTANCE_NAME of the Zookeeper container (i.e. 'zk1')
                          - The option '-e KAFKA_advertised.host.name=kf1.weave.local' because otherwise we are having problems when a client tries to connect using the server name:
                               - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Kafka container (i.e. 'kf1')
                          - The option '-e KAFKA_num.partitions=60' defines the default number of partitions by topic:
                               - It is a very important parameter because it is determining the maximum number of parallel workers we can have

-> Volumes mapping:
      - '-v dbkf1lib:/var/lib/kafka' is mapping the data (i.e. the 'logs') directory to the volume
      - '-v dbkf1log:/var/log/kafka' is mapping the log directory to the volume
      - '-v dbkf1sec:/etc/security:rw' is mapping the security directory to the volume



******* OBSERVATIONS ******************

-> In the name of the servers only use letters and numbers (but not '.' or '-' or '_' or another special characters):
      - Using special characters in the server 's names could lead to strange problems
