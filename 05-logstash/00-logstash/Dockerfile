
# Extending the official Logstash image

FROM logstash:2.3.2
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# Environment variables
ENV INSTANCE_NAME "lstash1"
ENV BOOTSTRAP_SERVERS "kf1:9092"

# Upgrade the 'Apache Kafka' output plugin
RUN yes Y | opt/logstash/bin/logstash-plugin update logstash-output-kafka

# Upgrade the 'Apache Kafka' input plugin
RUN yes Y | opt/logstash/bin/logstash-plugin update logstash-input-kafka
