
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to test the working of the pooling services



******* NEEDED ******************

-> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)


******* STEPS ******************


1. Start all the needed containers using Weave in the following order:
   1.1. Master PostgreSQL ( -> its Weave hostname is 'pg1')
   1.2. Slave PostgreSQL (-> its Weave hostname is 'pg2')
   1.3. Pooling service (-> its Weave hostname is 'pool1')

2. Attach to the Docker container that is running the Pooling Service (it is used to run the tests):
      - docker ps
           - In order to get the ID of the Docker container running the Pooling service
      - docker exec -it ID /bin/bash
           - Where ID is the id of the Docker container running the Pooling service

3. Start to test from the shell inside of the Docker container running the Pooling Service:
      - Test the access to the database:
           - export PGPASSWORD='challenge' && psql -p 5432 -h pool1 -U challenge -d challenge
                - p: port where the pg server is running
                - h: host where the pg server is running
                - U: the user to connect to the pg server
                        - The password for the user is provided by the environment variable:
                             - PGPASSWORD
                - d: the database to connect in the pg server
      - In order to visualize the log files:
           - Assuming that the volume 's name is 'dbpool1':
                - vi /var/lib/docker/volumes/dbpool1/_data/pgpool.log
                - vi /var/lib/docker/volumes/dbpool1/_data/pgbouncer.log
                     - Where the '/var/lib/docker/volumes/dbpool1/_data' is the volume's location in the host:
                          - docker volume inspect dbpool1
           - If in the log appears a message like 'Backend status file /var/log/pgpool/pgpool_status does not exist' don't worry, that is OK:
                - This file exists to record current status of each DB nodes. That means for the first time you run pgpool it will not find the file and
                  automatically creates it for the next time:
                     - http://blog.gmane.org/gmane.comp.db.postgresql.pgpool.general/month=20100701


******* OBSERVATIONS ******************

-> In order to have debugging messages when testing:
      1. In the file 'supervisor.conf' change the line 'command=pgpool -f /etc/pgpool/pgpool.conf -n' by:
            - 'command=pgpool -f /etc/pgpool/pgpool.conf -n --debug'
      2. In the file 'pgpool.conf' set the following paramaters:
            - 'log_connections = on'
            - 'debug_level = 1'
      3. Generate a new image:
            - docker build -t uyjco0/pooling:01 .
      4. Run the tests with this image
      5. When the tests are done, undo the above changes and generate a new image 
