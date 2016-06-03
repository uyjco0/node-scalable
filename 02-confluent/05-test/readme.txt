
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to test the working of the Confluent system



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
   1.1. Zookeeper (-> its Weave hostname is 'zk1')
   1.2. Kafka (-> its Weave hostname is 'kf1')
   1.3. Schema Registry (-> its Weave hostname is 'sr1')
   1.4. Rest Proxy (-> its Weave hostname is 'rp1')

2. Start an interactive Docker container (it is used to run the tests):
      - eval $(weave env)
      - docker run -ti --rm --name kafkatest --entrypoint=/bin/bash uyjco0/confluent-base:01:
           - It is needed to override the ENTRYPOINT instruction in the base image

3. If inside of the Docker container is needed to test something and the needed program is not installed:
      - The Docker container is a normal Ubuntu linux, so install what is needed:
           - For example:
                - Installing 'ping' (in order to test DNS resolution and networking):
                     - apt-get install iputils-ping
                - Installing 'telnet' (in order to test if a server 's port is open):
                     - apt-get install xinetd telnetd
                     - /etc/init.d/xinetd start
                     - apt-get install telnet
                     - telnet kf1 9092

4. Start to test from the shell inside of the interactive Docker container:
      - Source:
           - http://docs.confluent.io/3.0.0/quickstart.html#quickstart
      - Issues:
           - Connection refused for the Producer and Consumer:
                - I was needed to provide it the URL for the Schema Registry:
                     - https://groups.google.com/forum/#!topic/confluent-platform/DX0t-w2Wig0
      4.1. cd confluent
      4.2. ./bin/kafka-avro-console-producer --broker-list kf1.weave.local:9092 --property schema.registry.url='http://sr1.weave.local:8081' --topic test --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"f1","type":"string"}]}':
            - The last output is something like 'SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]', and the program start to wait an entry for the keyboard:
                 - Type in the keyboard:
                      - {"f1": "value1"}
                           - Hit the 'ENTER' key
                      - {"f1": "value2"}
                           - Hit the 'ENTER' key
                      - {"f1": "value3"}
                           - Hit the 'ENTER' key
                 - Type 'CTRL-C' in order to end the producer 
      4.3. ./bin/kafka-avro-console-consumer --topic test --zookeeper zk1:2181 --property schema.registry.url='http://sr1.weave.local:8081' --from-beginning
              - The output is:
                   - {"f1":"value1"}
                     {"f1":"value3"}
                     {"f1":"value2"}
              - Type 'CTRL-C' in order to end the consumer

-> Start to test Zookeeper/Kafka/Schema/Rest:
      - Source:
           - http://docs.confluent.io/3.0.0/kafka-rest/docs/intro.html#quickstart
      4.3.1. cd confluent
      4.3.2. Inspect Topic Metadata:
            - curl "http://rp1.weave.local:8082/topics"
            - curl "http://rp1.weave.local:8082/topics/test"
            - curl "http://rp1.weave.local:8082/topics/test/partitions"
      4.3.3. Produce and Consume Avro Messages:
            - curl -X POST -H "Content-Type: application/vnd.kafka.avro.v1+json" --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "testUser"}}]}' "http://rp1.weave.local:8082/topics/avrotest"
            - curl -X POST -H "Content-Type: application/vnd.kafka.v1+json" --data '{"name": "my_consumer_instance", "format": "avro", "auto.offset.reset": "smallest"}' http://rp1.weave.local:8082/consumers/my_avro_consumer
            - curl -X DELETE http://rp1.weave.local:8082/consumers/my_avro_consumer/instances/my_consumer_instance
      4.3.4. Produce and Consume JSON Messages:
            - curl -X POST -H "Content-Type: application/vnd.kafka.json.v1+json" --data '{"records":[{"value":{"foo":"bar"}}]}' "http://rp1.weave.local:8082/topics/jsontest"
            - curl -X POST -H "Content-Type: application/vnd.kafka.v1+json" --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "smallest"}' http://rp1.weave.local:8082/consumers/my_json_consumer
            - curl -X GET -H "Accept: application/vnd.kafka.json.v1+json" http://rp1.weave.local:8082/consumers/my_json_consumer/instances/my_consumer_instance/topics/jsontest
            - curl -X DELETE http://rp1.weave.local:8082/consumers/my_json_consumer/instances/my_consumer_instance
