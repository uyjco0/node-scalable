
#
# The current Dockerfile is based on the following images and code:
#    1. https://github.com/confluentinc/docker-images
#    2. https://www.ivankrizsan.se/2015/08/08/creating-a-docker-image-with-ubuntu-and-java
#    3. https://github.com/grumpy-docker/docker-kafka
# 
# ---
#
# The official Confluent images are not used because they have a lot of problems, as for example:
#    - The current version of the Confluent 's Docker image for the Schema Registy is having a problem in order to start the Schema Registry:
#         - https://github.com/confluentinc/schema-registry/issues/321 
#


FROM java:8

MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# Install utilities
RUN apt-get -qqy update && apt-get -qqy install \
	apt-utils \
        curl \
        software-properties-common \
	unzip

# Confluent platform environment variables
ENV CONFLUENT_VERSION_BASE "3.0"
ENV CONFLUENT_VERSION "3.0.0-2.11"
ENV CONFLUENT_FOLDER "/usr/sbin/confluent"

# Download the Confluent platform
WORKDIR /tmp
RUN curl -o confluent.zip http://packages.confluent.io/archive/${CONFLUENT_VERSION_BASE}/confluent-${CONFLUENT_VERSION}.zip

# Install the Confluent platform
WORKDIR /usr/sbin
RUN unzip /tmp/confluent.zip && \
	rm /tmp/confluent.zip && \
        mv confluent* confluent


# The script in charge of starting the intended server
COPY start_server.sh /usr/sbin/

# Utility in order to edit in easy way a configuration file:
# The source is from:
#    - https://github.com/confluentinc/docker-images/tree/master/src/main
# ---
# In order to know how to generate the utility read:
#    - ./utils/readme.txt
WORKDIR /usr/sbin
RUN mkdir docker-utils
COPY ./utils/docker-utils/ docker-utils
COPY ./utils/docker-edit-properties .

# Send all logs to stdout (so that they are shown by `docker logs`)
RUN rm ${CONFLUENT_FOLDER}/etc/kafka/log4j.properties &&\
	echo 'log4j.rootLogger=INFO, stdout' >> ${CONFLUENT_FOLDER}/etc/kafka/log4j.properties &&\
    	echo 'log4j.appender.stdout=org.apache.log4j.ConsoleAppender' >> ${CONFLUENT_FOLDER}/etc/kafka/log4j.properties &&\
    	echo 'log4j.appender.stdout.layout=org.apache.log4j.PatternLayout' >> ${CONFLUENT_FOLDER}/etc/kafka/log4j.properties &&\
    	echo 'log4j.appender.stdout.layout.ConversionPattern=[%d] %p %m (%c)%n' >> ${CONFLUENT_FOLDER}/etc/kafka/log4j.properties

# The application 'docker-edit-properties' is needing in its classpath the file 'log4j.properties'
RUN cp ${CONFLUENT_FOLDER}/etc/kafka/log4j.properties /usr/sbin/

RUN chmod +x /usr/sbin/start_server.sh /usr/sbin/docker-edit-properties ${CONFLUENT_FOLDER}/bin/zookeeper-server-start ${CONFLUENT_FOLDER}/bin/kafka-server-start ${CONFLUENT_FOLDER}/bin/schema-registry-start ${CONFLUENT_FOLDER}/bin/kafka-rest-start

ENTRYPOINT [ "/usr/sbin/start_server.sh" ]
CMD []
