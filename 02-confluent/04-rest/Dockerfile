
FROM uyjco0/confluent-base:01
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# The script in charge of starting the Kafka server
COPY start_server.sh /usr/sbin/

RUN ["chmod", "+x", "/usr/sbin/start_server.sh"]

EXPOSE 8082

# Application environment variables
ENV INSTANCE_NAME "rp1"

ENTRYPOINT [ "/usr/sbin/start_server.sh" ]
CMD []
