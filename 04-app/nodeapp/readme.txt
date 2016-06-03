
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>




******* GOAL ******************

-> It is providing the implementation of the 'Web services' block:
      - The 'Web services' are implemented as a 'node-web' cluster:
           - The '04-app/nodeapp/lib/web.js' is implementing the 'Web service'
             functionality:
                - It is offering to the application 's client to upload CSV
                  files straight to the PostgreSQL database

-> It is providing the implementation of some of the 'Workers' block:
      - The '04-app/nodeapp/lib/worker.js' is implementing a particular kind
        of 'Worker' functionality:
           - It is subscribed to the Confluent Platform, so each time that
             a change has ocurred in the PostgreSQL database, it runs a
             simple task
