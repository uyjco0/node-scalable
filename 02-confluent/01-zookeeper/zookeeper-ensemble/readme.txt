
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate Docker ZOOKEEPER images that are able to work together in an ensemble


******* NEEDED ******************

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)


******* GENERATE THE ZOOKEEPER IMAGE ******************

-> docker build -t uyjco0/baqend-conf-zookeeper:01 .



******* USING THE ZOOKEEPER IMAGE ******************

-> There are two options:
      1. Standalone:
            - docker run -d --restart=always --name zk1 -e INSTANCE_NAME=zk1 uyjco0/baqend-conf-zookeeper:01 1
      2. In an ensemble:
            - docker run -d --restart=always --name zk1 -e INSTANCE_NAME=zk1 uyjco0/baqend-conf-zookeeper:01 zk1,zk2 1
                 - The values 'zk1,zk2' are the hostnames of the Zookeeper servers, and '1' is the 'myid' value
            - docker run -d --restart=always --name zk2 -e INSTANCE_NAME=zk2 uyjco0/baqend-conf-zookeeper:01 zk1,zk2 2


******* OBSERVATIONS ******************

-> In the name of the servers only use letters and numbers (but not '.' or '-' or '_' or another special characters):
      - Using special characters in the server 's names could lead to strange problems

-> It is working fine with the Kafka server delivered by the 'Confluent plataform':
      - i.e. https://hub.docker.com/r/confluent/kafka
