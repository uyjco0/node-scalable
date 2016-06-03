

## Demo of a scalable and distributed application

The current project is building a demo of a scalable and distributed application composed by Node.js-based web and worker instances with a PostgreSQL master/slave backend.

The scalability and distributed properties are built using:
* Apache Zookeeper
* Apache Kafka 
* Confluent Schema Registry
* Confluent Rest Proxy
* Confluent Bottledwater Plugin/Client
* Node.js
* Docker
* Weave
* Supervisor
* HAProxy
* PgBouncer
* PgPool
* PostreSQL with Streaming Replication and Logical Decoding
* Logstash


Application behavior:
* The application 's end user is able to load a CSV file in the PostgreSQL backend through some of the available 'node-web' instances:
    * Each instance is a Node.js-based HTTP server
    * The CSV file is loaded to the database using a Node.js stream:
        * Once a CSV file is loaded to the database, the added file 's lines are automatically streamed to Apache Kafka by using the Bottledwater-pg plugin/client:
            * These message are serialized using Avro
* Each message (i.e. each added file 's line) in Apache Kafka is processed by the available 'node-worker' instances:
    * Each instance is a Node.js-based worker daemon
    * A 'node-worker' instance is using the Confluent Rest Proxy in order to be able to consume Avro-serialized messages from Apache Kafka: 
        * In turn the Confluent Rest Proxy (and also the Bottledwater-pg Client) are making use of the Confluent Schema Registry in order to avoid sending within each message the corresponding Avro 's schema (and thus saving bandwith/latency)
    * For each message the 'node-worker' instance in turn is making a read query to the PostgreSQL backend:
        * So depending of the rate of CSV files being loaded to the database, and the number of lines that each CSV file has, it is possible to have thousand of concurrent connections to the database (read queries)
* Producer Logstash workers are collecting all the application logs and sending them to Apache Kafka:
    * At the same time consumer Logstash workers are consuming the application logs from Apache Kafka, and processing them

Application scalability:
* The application is able to scale vertical/horizontally in order to manage its load

Where to start?:
* ./07-docs/readme.txt
