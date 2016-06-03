
FROM uyjco0/confluent-base:01
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# Kafka environment variables
ENV LOG_DIR "/var/log/kafka"
ENV KAFKA_LOG_DIRS "/var/lib/kafka"

# The script in charge of starting the Kafka server
COPY start_server.sh /usr/sbin/

# The script in charge of creating a topic 
COPY create_topic.sh /usr/sbin/

RUN ["mkdir", "-p", "/var/lib/kafka", "/var/log/kafka", "/etc/security"]
RUN ["chmod", "+x", "/usr/sbin/start_server.sh", "/usr/sbin/create_topic.sh"]

EXPOSE 9002

VOLUME ["/var/lib/kafka", "/var/log/kafka", "/etc/security"]

# Application environment variables
ENV INSTANCE_NAME "kf1"

ENTRYPOINT [ "/usr/sbin/start_server.sh" ]
CMD []
