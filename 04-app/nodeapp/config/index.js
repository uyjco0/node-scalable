
/**
 * It is defining the general configuration options for the application
 *
 *  @author Jorge Couchet <jorge.couchet@gmail.com>
 *
**/

      // The file with the paswords
var   secret = require('./secret')

    , config = {
                  // The application instance name
                  'instance_name': (process.env.INSTANCE_NAME || 'node1')

                  // The port that Node.js is listening
                , 'httpServerPort': (process.env.PORT || 3000)

                  // The server where Node.js is running:
                  //    - When using 'weave' the container name and
                  //      the instance name must be equal
                , 'host': (process.env.INSTANCE_NAME || 'localhost')

                  // The log file for the application
                , 'log_folder': (process.env.LOG_PATH || '/var/log/nodeapp')

		  // Options related with the database 
                , 'db': {
			  'host': (process.env.DB_HOST || 'localhost')
	                , 'port': 5432
	                , 'database': 'challenge'
                        , 'user': 'challenge'
	                , 'password': secret.db_password

			  // When using an external pooling solution, then the size should be 1
                	  // in order to avoid double-pooling:
                	  //    - Source:
                	  //         - https://github.com/brianc/node-postgres/issues/975
			, 'pool_size': 1
		  }

                  // If memory profiling is enabled it is the maximum amount of snapshots to take
		, 'max_snapshots': 3 

		  // Options related with the Kafka configuration for the worker server
		, 'kafka': {
			     'rest_proxy_host': 'rp1'
			   , 'rest_proxy_port': 8082
			     // The name of the topic being consumed by the worker
			   , 'topic_name': 'csvs'
                             // The name of the Consumer Group to which the worker belongs
			   , 'consumer_group_name': 'cg_csv'
			     // It says the worker if start to consume from the beginning of the stream or from the last
			     // From where the worker must start when still there is not a committed offset
			   , 'from_beginning': 1
		  }
      };

module.exports = config;
