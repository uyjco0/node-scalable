

******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>




******* GOAL ******************

-> Here are the instructions to generate Docker Confluent ZOOKEEPER image



******* SOURCES ******************

-> It is reusing (but modified) code from:
      - https://github.com/confluentinc/docker-images



******* NEEDED ******************

-> When starting the Confluent system, the Zookeeper containers need to be started the first


-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)

-> Creating a named volume:
      - Delete the volume if it already exists (if it is needed):
           - docker volume rm dbzk1lib
           - docker volume rm dbzk1log
      - Creating the needed volumes:
           - docker volume create --name dbzk1lib
           - docker volume create --name dbzk1log
      - We can see where is the physical folder in the host for the volume with:
           - docker volume inspect dbzk1lib



******* GENERATE THE CONFLUENT ZOOKEEPER IMAGE ******************

-> docker build -t uyjco0/confluent-zookeeper:01 .



******* USING THE CONFLUENT ZOOKEEPER IMAGE ******************

-> Running a standalone Zookeeper server:
      - docker run -d --restart=always --name zk1 -e INSTANCE_NAME=zk1 -e zk_id=1 -v dbzk1lib:/var/lib/zookeeper:rw -v dbzk1log:/var/log/zookeeper -p 2181:2181 uyjco0/confluent-zookeeper:01

-> Available '-e' flags for running the container:
      - INSTANCE_NAME: the instance name, if using 'weave' it must be the same that the container name (i.e. '--name')
           - Default is 'zk1' 
      - ZK_CFG_URL: the URL from where to download the configuration files
      - ZK_{zookeeper_configuration_parameter}:
           - It is possible to add any Zookeeper configuration parameter:
                - They are defined at: https://zookeeper.apache.org/doc/r3.3.2/zookeeperAdmin.html
                - As for example when used in an ensemble configuration it is possible to define:
                     - '-e zk_server.1=zk1:2888:3888':
                          - Where the zookeeper configuration parameter is 'server.1'
                          - If using 'weave networking' it will be the same that the INSTANCE_NAME of the Zookeeper container (i.e. 'zk1')
           - It is also possible to use in lowercase:
                - i.e. zk_{zookeeper_configuration_parameter}

-> Volumes mapping:  
      - '-v dbzk1lib:/var/lib/zookeeper:rw' maps the data directory to the volume
      - '-v dbzk1log:/var/log/zookeeper' maps the log directory to the volume



******* OBSERVATIONS ******************

-> If we want to run an ensemble the command will be:
      - docker run -d --name zk1 -e INSTANCE_NAME=zk1 -e zk_id=1 -e zk_server.1=zk1:2888:3888 -e zk_server.2=zk2:2888:3888 -v dbzk1lib:/var/lib/zookeeper:rw -v dbzk1log:/var/log/zookeeper -p 2181:2181 uyjco0/confluent-zookeeper:01 :
      - Currently is not possible to make to work the ensemble (at least when both servers are running in the same host):
           - The problem is that the first server to start cannot resolve the name of the second server (but the second server is able to resolve the name of the first):
                - The problem appears to be related with the Zookeeper version being used:
                     - https://github.com/weaveworks/weave/issues/632
                - It is solved by using the current version of zookeeper ( it is 3.4.8, while the Confluent platform is using the 3.4.6-1569965):
                     - In './zookeeper-ensemble' there is an example that solves the problem using the current version of zookeeper (3.4.8)

-> In the name of the servers only use letters and numbers (but not '.' or '-' or '_' or another special characters):
      - Using special characters in the server 's names could lead to strange problems
