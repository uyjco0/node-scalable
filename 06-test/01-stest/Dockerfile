
#
# It builds an image to run the stress/performance tools 'ab' and 'wrk':
#    - ab:
#         - https://httpd.apache.org/docs/2.4/programs/ab.html
#    - wrk:
#         - https://github.com/wg/wrk
# 

FROM buildpack-deps:xenial
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# Install 'ab' and the needed tools in order to instal 'wrk'
RUN apt-get -qqy update && apt-get -qqy install \
        apache2-utils \
	apt-utils \
        build-essential \
        cmake \
        libssl-dev \
        git \
        software-properties-common

# Install 'wrk'
WORKDIR /usr/sbin/
RUN git clone https://github.com/wg/wrk.git
RUN cd wrk && make && cp wrk /usr/local/bin

ENV INSTANCE_NAME "stest1"

# The mount point for the application files
RUN mkdir -p /opt/stest

VOLUME [ "/opt/stest" ]

WORKDIR /opt/stest
ENTRYPOINT [ "./start_stest.sh" ]
CMD [ "ab", "1000", "16", "y", "http://webg1.weave.local/upload" ]
