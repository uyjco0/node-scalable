
#
# It is a modified Makefile from:
#    - Source:
#         - https://github.com/confluentinc/bottledwater-pg/blob/master/Makefile
#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#


DOCKER_TAG = 01

.PHONY: all install clean

all:
	$(MAKE) -C ext all
	$(MAKE) -C client all
	$(MAKE) -C kafka all

install:
	$(MAKE) -C ext install

clean:
	$(MAKE) -C ext clean
	$(MAKE) -C client clean
	$(MAKE) -C kafka clean

docker: docker-client docker-postgres

docker-compose: docker
	docker-compose build

tmp:
	mkdir tmp

tmp/%.tar.gz: tmp docker-build
	docker run --rm uyjco0/pg-plugin:$(DOCKER_TAG) cat /$*.tar.gz > $@

tmp/%: build/% tmp
	cp $< $@

docker-build:
	docker build -f build/Dockerfile.build -t uyjco0/postgres-bw-plugin:$(DOCKER_TAG) .

docker-client: tmp/Dockerfile.client tmp/avro.tar.gz tmp/librdkafka.tar.gz tmp/bottledwater-bin.tar.gz tmp/bottledwater-docker-wrapper.sh
	docker build -f $< -t uyjco0/bw-client:$(DOCKER_TAG) tmp

docker-postgres: tmp/Dockerfile.postgres tmp/bottledwater-ext.tar.gz tmp/avro.tar.gz tmp/replication-config.sh
	docker build -f $< -t local-postgres-bw:$(DOCKER_TAG) tmp
