
#
#
# It builds a 'PgBouncer' and 'pgpool-II' image running with 'supervisor':
#    - It means that the main process in the Docker container is
#      'supervisor', and it in turn is running:
#         - 'PgBouncer'
#         - 'pgpool'
# 
#

FROM postgres:9.5.2
MAINTAINER Jorge Couchet <jorge.couchet@gmail.com>

# The source from which was taken the option '--force-yes':
#    - https://github.com/confluentinc/bottledwater-pg/blob/master/build/Dockerfile.build 
RUN apt-get update && \
    # --force-yes is needed because we may need to downgrade libpq5 to $PG_MAJOR
    # (set by the postgres:9.5 Docker image).  Confusingly the postgres:x.y
    # Docker images have been known to include libpq5 version > x.y, which we
    # may not yet be compatible with, so we can't rely on just specifying the
    # image tag to pin the libpq version.
    apt-get install -y --no-install-recommends --force-yes \
        build-essential \
        cmake \
        wget \
        libcurl4-openssl-dev \
        libevent-dev \
        libpq5=${PG_MAJOR}\* \
        libpq-dev=${PG_MAJOR}\* \
        postgresql-server-dev-${PG_MAJOR}=${PG_MAJOR}\* \
        supervisor

WORKDIR /usr/local

ENV PGPOOL_VERSION=3.5.2

# Intall pgpool-II
RUN wget http://www.pgpool.net/download.php?f=pgpool-II-${PGPOOL_VERSION}.tar.gz -O pgpool-II-${PGPOOL_VERSION}.tar.gz && \
    tar -zxvf pgpool-II-${PGPOOL_VERSION}.tar.gz && \
    rm pgpool-II-${PGPOOL_VERSION}.tar.gz && \
    mv pgpool-II-${PGPOOL_VERSION} pgpool && \
    cd pgpool && \
    ./configure --prefix=/usr/local && \
    make && make install


ENV PGBOUNCER_VERSION=1.7.2

# Intall PgBouncer
RUN wget http://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz -O pgbouncer-${PGBOUNCER_VERSION}.tar.gz && \
    tar -xzf pgbouncer-${PGBOUNCER_VERSION}.tar.gz && \
    rm pgbouncer-${PGBOUNCER_VERSION}.tar.gz && \
    mv pgbouncer-${PGBOUNCER_VERSION} pgbouncer && \
    cd pgbouncer && \
    ./configure --prefix=/usr/local --with-libevent=libevent-prefix && \
    make && make install


# HAProxy environment variables
ENV HAPROXY_VERSION_BASE "1.6"
ENV HAPROXY_VERSION "1.6.5"

RUN wget http://www.haproxy.org/download/${HAPROXY_VERSION_BASE}/src/haproxy-${HAPROXY_VERSION}.tar.gz
RUN tar xzf haproxy-${HAPROXY_VERSION}.tar.gz
RUN rm haproxy-${HAPROXY_VERSION}.tar.gz
RUN mv haproxy-${HAPROXY_VERSION} haproxy
RUN cd haproxy && make TARGET=generic && make install
    

ENV INSTANCE_NAME pool1

# The application log file
ENV LOG_PATH /var/log/pooling
RUN mkdir -p /var/log/pooling
RUN chown postgres /var/log/pooling

VOLUME [ "/var/log/pooling" ]

# Configure 'supervisor'
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# Configure 'pgpool'
RUN mkdir -p /var/run/pgpool
RUN chown postgres /var/run/pgpool
RUN mkdir -p /etc/pgpool
RUN chown postgres /etc/pgpool
COPY pgpool.conf /etc/pgpool
COPY pool_passwd /etc/pgpool
COPY pool_hba.conf /usr/local/etc

# Configure 'PgBouncer'
RUN mkdir -p /var/run/pgbouncer
RUN chown postgres /var/run/pgbouncer
RUN mkdir -p /etc/pgbouncer
RUN chown postgres /etc/pgbouncer
COPY pgbouncer.ini /etc/pgbouncer
COPY users.txt /etc/pgbouncer

# Configure 'HAProxy'
RUN mkdir -p /etc/haproxy
COPY haproxy.cfg /etc/haproxy

# pgpool=2000, pgpool_pcp=2001, pgbouncer=5426, haproxy=5427 5428 5429 5430 5431 5432
EXPOSE 2000 2001 5426 5427 5428 5429 5430 5431 5432

ENTRYPOINT [ "/usr/bin/supervisord", "--config", "/etc/supervisor/conf.d/supervisor.conf" ]
