
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate Docker Confluent SCHEMA REGISTRY image



******* SOURCES ******************

-> It is reusing (but modified) code from:
      - https://github.com/confluentinc/docker-images



******* NEEDED ******************

-> When starting the Confluent system, the Schema Register containers are started third (the Zookeeper containers are started first, and the Kafka containers second)

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)



******* GENERATE THE CONFLUENT SCHEMA REGISTRY IMAGE ******************

-> docker build -t uyjco0/confluent-schema:01 .



******* USING THE CONFLUENT SCHEMA REGISTRY IMAGE ******************

-> docker run -d --restart=always --name sr1 -e INSTANCE_NAME=sr1 -e SR_kafkastore.connection.url=zk1:2181 -p 8081:8081 uyjco0/custom_confluent_schema:01

-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'sr1'
      - SR_{schema_registry_configuration_parameter}:
           - It is possible to add any Schema Registry configuration parameter:
                - They are defined at: http://docs.confluent.io/3.0.0/schema-registry/docs/config.html
                - As for example: 
                     - The option '-e SR_kafkastore.connection.url=zk1:2181' tells the Schema Registry where is the Zookeeper server:
                          - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Zookeeper container (i.e. 'zk1')
           - It is also possible to use an alternative syntax:
                - SCHEMA_REGISTRY_{schema_registry_configuration_parameter}



******* OBSERVATIONS ******************

-> In the name of the servers only use letters and numbers (but not '.' or '-' or '_' or another special characters):
      - Using special characters in the server 's names could lead to strange problems

-> The current version of the Confluent 's Docker image for the Schema Registy is having a problem in order to start the Schema Registry:
      - https://github.com/confluentinc/schema-registry/issues/321
