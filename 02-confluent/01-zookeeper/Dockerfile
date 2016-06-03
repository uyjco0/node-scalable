
FROM uyjco0/confluent-base:01
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# Zookeeper environment variables
ENV LOG_DIR "/var/log/zookeeper"
ENV ZK_DATA_DIR "/var/lab/zookeeper"
ENV KAFKA_LOG4J_OPTS -Dlog4j.configuration=file:${CONFLUENT_FOLDER}/etc/kafka/log4j.properties

# The script in charge of starting the Zookeeper server
COPY start_server.sh /usr/sbin/

RUN ["mkdir", "-p", "/var/log/zookeeper", "/var/lib/zookeeper"]
RUN ["chmod", "+x", "/usr/sbin/start_server.sh"]

# Expose client port (2188/tcp), peer connection port (2888/tcp), leader election port (3888/tcp)
EXPOSE 2181 2888 3888

VOLUME ["/var/log/zookeeper", "/var/lib/zookeeper"]

# Application environment variables
ENV INSTANCE_NAME "zk1"

ENTRYPOINT [ "/usr/sbin/start_server.sh" ]
CMD []
