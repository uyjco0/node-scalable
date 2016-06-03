
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate a base CONFLUENT image:
      - This base image will be later extended to generate the images for ZOOKEEPER, KAFKA, SCHEMA REGISTRY and REST PROXY
      - It is not using the official Docker CONFLUENT Image because it has several problems right now


******* SOURCES ******************

-> It is reusing (but modified) code from:
      - https://github.com/confluentinc/docker-images
      - https://www.ivankrizsan.se/2015/08/08/creating-a-docker-image-with-ubuntu-and-java


******* NEEDED ******************

-> First it is needed to generate the utility 'docker-edit-properties':
      - Read the instructions in './utils/readme.txt' 


******* GENERATE THE CONFLUENT BASE IMAGE ******************

-> docker build -t uyjco0/confluent-base:01 .
