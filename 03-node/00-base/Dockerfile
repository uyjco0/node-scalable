
# Extending the official Node image

FROM node:6.1.0
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# Installing the extra needed tools
RUN apt-get -yqq update && apt-get -yqq install \
    supervisor

# The folder where are the application files
RUN mkdir -p /opt/nodeapp

# Environment variables
ENV DB_HOST "pool1"
ENV DB_PORT 5432
ENV DB_DATABASE "challenge"
ENV DB_USER "challenge"
ENV DB_PASSWORD "challenge"
ENV DB_POOL_SIZE 1
ENV MEMORY_PROFILING "n"

VOLUME [ "/opt/nodeapp" ]

WORKDIR /opt/nodeapp
