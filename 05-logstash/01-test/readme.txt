
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>




******* GOAL ******************

-> Here are the instructions to test the working of Logstash running as a particular kind 
   of 'Worker' that is an Apache Kafka 's producer



******* NEEDED ******************

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)


******* STEPS ******************


1. Start all the needed containers using Weave in the following order:
   1.1. Master PostgreSQL (-> its Weave hostname is 'pg1')
   1.2. Slave PostgreSQL (-> its Weave hostname is 'pg2')
   1.3. Pooling service (-> its Weave hostname is 'pool1')
   1.4. Apache Zookeeper server (-> its Weave hostname is 'zk1')
   1.5. Apache Kafka server (-> its Weave hostname is 'kf1')
   1.6. Confluent Schema Registry (-> its Weave hostname is 'sr1')
   1.7. Confluent Rest Proxy (-> its Weave hostname is 'rp1')


2. Start a Docker container with the Apache Kafka binaries:
      - eval $(weave env)
      - docker run -ti --rm --name kafkatest --entrypoint=/bin/bash uyjco0/confluent-base:01

3. Start to test from the shell inside of the Docker container with the Apache Kafka binaries:
      - confluent/bin/kafka-console-consumer --topic logstash --zookeeper zk1:2181 --from-beginning:
           - It should show all the messages from the different logs in JSON format
           - As an alternative we can run the command:
                - confluent/bin/kafka-console-consumer --topic logstash --from-beginning --new-consumer --bootstrap-server "kf1:9092"
      - Type 'CTRL-C' to end the consumer
