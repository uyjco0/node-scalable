
#
# Extending the NODE base image:
#    - It builds a cluster of 'worker' nodes running with 'supervisor':
#         - It means that the main process in the Docker container is
#           'supervisord', and it in turn is running:
#              - The 'worker' nodes
#


FROM uyjco0/node-base:01
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>


# Configure 'supervisor'
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# The application log file
RUN mkdir -p /var/log/nodeapp

# Environment variables
ENV INSTANCE_NAME "worker1"
ENV DB_PORT "5427,5428,5429,5430,5431"
ENV LOG_PATH "/var/log/nodeapp"
ENV KAFKA_REST_PROXY_HOST "rp1"
ENV KAFKA_REST_PROXY_PORT 8082
ENV KAFKA_TOPIC_NAME "csvs"
ENV KAFKA_CONSUMER_GROUP_NAME "cg_csv"
ENV KAFKA_FROM_BEGINNING 1

VOLUME [ "/var/log/nodeapp" ]

# Copy the start script
COPY start.sh /usr/sbin/
RUN chmod +x /usr/sbin/start.sh

ENTRYPOINT [ "/usr/sbin/start.sh" ]
