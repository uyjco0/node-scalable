
#
# Extending the NODE base image:
#    - It builds a cluster of 'web' nodes running with 'supervisor':
#         - It means that the main process in the Docker container is
#           'supervisord', and it in turn is running:
#              - The 'web' nodes
#


FROM uyjco0/node-base:01
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>


# HAProxy environment variables
ENV HAPROXY_VERSION_BASE "1.6"
ENV HAPROXY_VERSION "1.6.5"

WORKDIR /opt
RUN wget http://www.haproxy.org/download/${HAPROXY_VERSION_BASE}/src/haproxy-${HAPROXY_VERSION}.tar.gz
RUN tar xzf haproxy-${HAPROXY_VERSION}.tar.gz
RUN rm haproxy-${HAPROXY_VERSION}.tar.gz
RUN mv haproxy-${HAPROXY_VERSION} haproxy
RUN cd haproxy && make TARGET=generic && make install

# Configure 'haproxy'
COPY haproxy.cfg /opt/haproxy/haproxy.cfg

# Configure 'supervisor'
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# The application log file
RUN mkdir -p /var/log/nodeapp

# Environment variables
ENV INSTANCE_NAME "webg1"
ENV LOG_PATH "/var/log/nodeapp"
ENV PORT 3000

VOLUME [ "/var/log/nodeapp" ]

# The different ports exposed by the workers
EXPOSE $PORT

# Copy the start script
COPY start.sh /usr/sbin/
RUN chmod +x /usr/sbin/start.sh

ENTRYPOINT [ "/usr/sbin/start.sh" ]
