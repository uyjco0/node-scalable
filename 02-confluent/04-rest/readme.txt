
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate Docker Confluent REST PROXY image



******* SOURCES ******************

-> It is reusing (but modified) code from:
      - https://github.com/confluentinc/docker-images



******* NEEDED ******************

-> When starting the Confluent system, the Rest Proxy containers are started fourth (the Zookeeper containers are started first, the Kafka containers second, and the Schema Registry containers third)

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)


******* GENERATE THE CONFLUENT REST PROXY IMAGE *****************

-> docker build -t uyjco0/confluent-rest:01 .



******* GENERATE THE CONFLUENT REST PROXY IMAGE *****************

-> docker run -d --restart=always --name rp1 -e INSTANCE_NAME=rp1 -e RP_id=1 -e RP_zookeeper.connect=zk1:2181 -e RP_schema.registry.url=http://sr1.weave.local:8081 -p 8082:8082 uyjco0/custom_confluent_rest:01


-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'rp1'
      - RP_{rest_proxy_configuration_parameter}:
           - It is possible to add any Rest Proxy configuration parameter:
                - They are defined at: http://docs.confluent.io/3.0.0/kafka-rest/docs/config.html
                - As for example:
                     - The option '-e RP_zookeeper.connect=zk1:2181' tells the Rest Proxy where is the Zookeeper server:
                          - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Zookeeper container (i.e. 'zk1')
                     - The option '-e RP_schema.registry.url=http://sr1:8081' tells the Rest Proxy where is the Schema Registry:
                          - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Schema Registry container (i.e. 'sr1')
           - It is also possible to use an alternative syntax:
                - KAFKA_REST_{rest_proxy_configuration_parameter}  



******* OBSERVATIONS ******************

-> In the name of the servers only use letters and numbers (but not '.' or '-' or '_' or another special characters):
      - Using special characters in the server 's names could lead to strange problems
