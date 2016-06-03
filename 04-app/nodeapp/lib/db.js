
/**
 *
 * Database functions to be used by other modules using the singleton pattern:
 *    - Here it is being directly used the database interface 'Client' from 
 *      the module 'node-postgres':
 *         - The caveat with this approach is thaf if the application is not using an
 *           external connection pool (as 'PgBouncer' or 'pgpool'), and it tries to
 *           make more connections than the maximum of connections that the PostgreSQL
 *           database is set to serve, then the database will have a problem
 *              - An alternative approach will be to use instead the 'pg' root object
 *                from the module 'node-postgres':
 *                   - In this case in order to avoid double-pooling, it is needed to
 *                     set 'pg.defaults.poolSize' to 1:
 *                        - Source:
 *                             - https://github.com/brianc/node-postgres/issues/975
 *
 * @author Jorge Couchet <jorge.couchet@gmail.com>
 *
 *
**/

    // Singleton
var resm = null;

module.exports = function(config, logger) {

	var   place = ''
            , pg = null
            , db_params = null
            , ports = null;

	if (!resm) {

		resm = { 
			  'connect': null

                        , 'connect_with_index': null

			, 'client': null

                        , 'client_with_index': null

			, 'pgc': require('pg-copy-streams').from
                     
			, 'ports_amount': 1
		}

                place = 'lib/db.js';

		pg = require('pg');

		// When using an external pooling solution, then the size should be 1
                // in order to avoid double-pooling:
                //    - Source:
                //         - https://github.com/brianc/node-postgres/issues/975
		pg.defaults.poolSize = process.env.DB_POOL_SIZE || config.db.pool_size;

		// Object with all the database parameters
		db_params = {
                              database: process.env.DB_DATABASE || config.db.database
                            , user: process.env.DB_USER || config.db.user
                            , password: process.env.DB_PASSWORD || config.db.password
                            , host: process.env.DB_HOST || config.db.host
                            , ports: []
                            , conns_url: []
                };


		// It checks if there is the environment variable DB_PORT, and if it has some value
		if (process.env.hasOwnProperty('DB_PORT') && process.env.DB_PORT) {

			// The environment variable DB_PORT can have the following formats:
                        //    - DB_PORT = 5432
                        //    - DB_PORT = 5432,5431,5430
			ports = String(process.env.DB_PORT).split(',');

                	for (i = 0; i < ports.length; i++) {

				// Check if the current port hasn't a falsy value as NaN or 0				
				if (ports[i]) {
					
					db_params.ports.push(ports[i]);

					// Create the database string connections for each port (but without the PostgreSQL default port)
					db_params.conns_url.push('postgres://' + db_params.user + ':' + db_params.password + '@' + db_params.host + ':' + ports[i] + '/' + db_params.database);
				}
			}

		} else {
		
			db_params.ports.push(config.db.port);

			db_params.conns_url.push('postgres://' + db_params.user + ':' + db_params.password + '@' + db_params.host + ':' + config.db.port + '/' + db_params.database);
		}


		/**
           	 * An idle client in the pool emitted an error and has been removed from the pool and destroyed.
           	 * An idle client will likely only emit an error when it loses connection to the PostgreSQL server 
                 * instance, for example when your database crashes.
		**/
		pg.on('error', function(err, client) {

			logger.log_err(logger.logger, place, 'main', 1, err, 'There is an error with the database: ' + db_params.database);
		});


		// Set the real amount of available database ports
		resm.ports_amount = db_params.ports.length;


		/** 
		 * Connect to the database using the first available  database port and create the connection pool with size 'pg.defaults.poolSize'. 
		 * If it is already connected, then is is only returning a 'client' from the database 's connection pool
        	 * ---
        	 * The 'fn' callback is receiving as parameters 'err', 'client' and 'done'. So, the 'fn' callback must 
        	 * be use 'done' in order to free the 'client' (i.e. return the 'client' to the database 's connection 
		 * pool)
        	**/
        	resm.connect = function(fn) {

			// It is using the in-built pool manager of database clients
            		pg.connect(db_params.conns_url[0], function(err, client, done) {

                		fn(err, client, done);
            		});
        	};
	

		/** 
                 * Connect to the database using an specifc database port:
                 *    - It is used to avoid the port exahustion problem:
                 *         - See more at:
                 *              - node-scalable/03-node/02-node-worker/readme.txt
                 *              - node-scalable/04-app/nodeapp/lib/worker.js 
                **/
                resm.connect_with_index = function(port_index, fn) {

			if (db_params.conns_url && (port_index >=0) && (port_index < db_params.conns_url.length)) {

                        	pg.connect(db_params.conns_url[port_index], function(err, client, done) {

                                	fn(err, client, done);
                        	});

			} else {

				pg.connect(db_params.conns_url[0], function(err, client, done) {

                                        fn(err, client, done);
                                });

			}
                };	


		/**
		 * Function to create a new interface 'Client' object using the first available database port to connect
		**/
		resm.client = function() {

			return new pg.Client(db_params.conns_url[0]);
        	};


		/**
		 * Function to create a new interface 'Client' object using an specific database port where connect:
                 *    - It is used to avoid the port exahustion problem:
                 *         - See more at:
                 *              - node-scalable/03-node/02-node-worker/readme.txt
                 *              - node-scalable/04-app/nodeapp/lib/worker.js
		**/
                resm.client_with_index = function(port_index) {

			if (db_params.conns_url && (port_index >=0) && (port_index < db_params.conns_url.length)) {

                        	return new pg.Client(db_params.conns_url[port_index]);
			} else {

				return new pg.Client(db_params.conns_url[0]);
			}
                };
	}

	return resm;
};
