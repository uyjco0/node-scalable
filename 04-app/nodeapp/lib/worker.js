
/**
 *
 * The functions to be used by the Node.js based Worker (i.e. 'node-worker'):
 *    - It is using:
 *         - confluentinc/kafka-rest-node:
 *              - Which in turn is a wrapper for the REST PROXY:
 *                   - http://docs.confluent.io/2.0.1/kafka-rest/docs/index.html
 *         - For the moment only the High Level Consumer is implemented
 *
 * @author Jorge Couchet <jorge.couchet@gmail.com>
 *
 *
**/

module.exports = function(config, logger, db) {

	var     resm = { start: null }

              , place = 'lib/worker.js'

		// The wrapper to access the Confluent Rest Proxy
	      , kafka_rest = require('kafka-rest')

		// Where to connect to the Confluent Rest Proxy in order to access the Apache Kafka 's consumer functionality:
                //    - The alternative is to use an implemented Node.js 's Apache Kafka consumer:
                //         - As for example:
		//              - https://github.com/oleksiyk/kafka
                //              - https://github.com/SOHU-Co/kafka-node
	      , kafka = new kafka_rest({ 'url': 'http://' + (process.env.KAFKA_REST_PROXY_HOST || config.kafka.rest_proxy_host) + ':' + (process.env.KAFKA_REST_PROXY_PORT || config.kafka.rest_proxy_port) })

		// The topic from which the worker will be consuming messages
              , topic_name = (process.env.KAFKA_TOPIC_NAME || config.kafka.topic_name)

		// The group to which the worker will belong, the available topic 's partitions are distributed among all the available workers in the group 
	      , consumer_group_name = (process.env.KAFKA_CONSUMER_GROUP_NAME || config.kafka.consumer_group_name)

	      , from_beginning = (process.env.KAFKA_FROM_BEGINNING || config.kafka.from_beginning)

		// The format being used to serialize the messages:
                //    - The Bottled Water Client was configured to use 'avro':
                //         - See at: 'bottledwater-docker-wrapper.sh'
	      , format = 'avro'

	        // Status variable that holds the current amount of consumed messages for the worker
	      , consumed = 0

                // It controls the consumer behavior
	      , consumer_config = null

		/**
		 * It logs the worker 's shutdown event
		**/
	      , log_shutdown = function(err) {
    
			if (err) {

				logger.log_err(logger.logger, place, 'log_shutdown', 1, err, 'Worker ' + process.env.INSTANCE_NAME + ' has an error while shutting down');

			} else {

				logger.log_info(logger.logger, place, 'log_shutdown', 2, 'Worker ' + process.env.INSTANCE_NAME + ' shutdown cleanly');
			}
		}

		/**
		 * It rotates the port index in order to avoid the port exahustion problem 
		**/
              , round_robin_port = function(db, current_port_index) {

			if (current_port_index < db.ports_amount-1) {

				return ++current_port_index;

			} else {

				return 0;
			}

                }
 
		/**
		 * It is in charge of processing the consumed messages:
		 *    - It is the one that is impacting the performance of the PostgreSQL slaves (if
                 *      it only making read queries, otherwise it is also impacting the PostgreSQL master)
		**/
	      , process_message = function(msg, current_port_index, fn) {

		              // Get a client using the current available database port
			var   db_client = db.client_with_index(current_port_index)
			    , names = null
                            , fname = '';

			// It connects to the database
			db_client.connect(function(err) {

                        	if(err) {

					db_client.end();
					db_client = null;

					logger.log_err(logger.logger, place, 'process_message', 1, err, 'Error while trying to connect to the database');

					return fn(err);

                        	} else {

					names = msg['name']['string'].split(" ");

					fname = names[0];
					
					// Query the database:
                                        //    - It counts the amount of rows that are having the same first name as the current message
                                        //         - The query is using a 'left anchored' pattern matching query, so the current index defined in
					//           the database is enough:
					//              - i.e. 'CREATE INDEX csvs_name_pattern_idx ON csvs(name varchar_pattern_ops)':
                                        //                   - http://www.postgresql.org/docs/9.5/static/indexes-types.html
                			//                   - http://www.postgresql.org/docs/9.5/static/indexes-opclass.html
					//         - But if queries with more complex pattern matching are used, then it is needed another kind of
					//           indexes:
                                        //              - A Trigram Index or Full Text Search:
                                        //                   - http://dba.stackexchange.com/questions/117403/faster-query-with-pattern-matching-on-multiple-text-fields
                                        //                   - http://dba.stackexchange.com/questions/2195/how-is-like-implemented/10856#10856
                                        //                   - http://linuxgazette.net/164/sephton.html
					db_client.query('SELECT count(*) FROM csvs WHERE name ILIKE $1', [ fname + '%' ], function(err, resqry) {

                                		db_client.end();
                                        	db_client = null;

						return fn(err, msg, resqry);
					});
                        	}
                	});

	        }

	       /**
                * It initializes the worker
	       **/
	     , worker_start = function() {

			var rp_stream = null;

			// It is possible also commit the messages manually
                	consumer_config = { "format": format, "auto.commit.enable": "true"};

                	// http://kafka.apache.org/documentation.html -> auto.offset.reset
                	if (from_beginning) {

                        	consumer_config['auto.offset.reset'] = 'smallest';
                	}

			// Join the worker to the Consumer Group:
                        //    - All the workers joined to the same Consumer Group are working in parallel
                	kafka.consumer(consumer_group_name).join(consumer_config, function(err, consumer_instance) {

				var current_port_index = -1;

                        	if (err) return logger.log_err(logger.logger, place, 'worker_start', 1, err, 'Worker ' + process.env.INSTANCE_NAME + ' has an error when creating the consumer');  

				logger.log_info(logger.logger, place, 'worker_start', 2, 'Worker ' + process.env.INSTANCE_NAME + ' has initialized consumer instance');

				// Manage some errors from the consumer instance
				consumer_instance.on('error', function(err) {

        				logger.log_err(logger.logger, place, 'worker_start', 3, err, 'There was an error with the worker ' + process.env.INSTANCE_NAME);

					consumer_instance.shutdown(log_shutdown);		
    				});

				// Suscribe the worker to the topic in order to start to consume messages:
                                //    - Here the topic is associated to a database table, so it is consuming messages each time the table is being modified
                        	rp_stream = consumer_instance.subscribe(topic_name);

                        	rp_stream.on('data', function(msgs) {

					// Amount of messages consumed until now by the worker
                                        consumed += msgs.length;

					// BEWARE!: it is an expensive operation:
                                        //    - It is only for a demonstration purpose
					logger.log_info(logger.logger, place, 'worker_start', 4, 'The amount of messages consumed is: ' + consumed);

					// Process all the consumed messages
                                	for(var i = 0; i < msgs.length; i++) {

						// Rotate the ports in order to avoid the port exahustion problem:
                                                //    - See at:
                                                //         - node-scalable/03-node/02-node-worker/readme.txt
						current_port_index = round_robin_port(db, current_port_index);
	
						// Do something with the individual consumed message	
                                        	process_message(msgs[i].value, current_port_index, function(err, msg, resqry) {

							// Here in the callback we can manually commit the offset for example

							// Check if there was some error with the query
							if (err) {

								logger.log_err(logger.logger, place, 'worker_start', 5, err, 'Worker ' + process.env.INSTANCE_NAME + ' has an error while consuming messages');

							} else {

								// BEWARE!: it is an expensive operation:
                                                                //    - It is only for a demonstration purpose
								logger.log_info(logger.logger, place, 'worker_start', 6, ' MESSAGE *** Name: ' + msg['name']['string'] + ' *** Email: ' + msg['email']['string'] + ' *** Count: ' + resqry.rows[0].count);
							}
						});
                                	}

                        	});

                        	rp_stream.on('error', function(err) {

					logger.log_err(logger.logger, place, 'worker_start', 7, err, 'Worker ' + process.env.INSTANCE_NAME + ' has an error with the stream to the Confluent Rest Proxy');

					rp_stream = null;

                                	consumer_instance.shutdown(log_shutdown);
                        	});

                        	rp_stream.on('end', function() {

					logger.log_info(logger.logger, place, 'worker_start', 8, 'Worker ' + process.env.INSTANCE_NAME + 'has received an end of the stream to the Confluent Rest Proxy');

					rp_stream = null;

					consumer_instance.shutdown(log_shutdown);

                        	});

                        	// Perform a clean clean shutdown when requested
                        	process.on('SIGINT', function() {

                                	consumer_instance.shutdown(log_shutdown);
                        	});
                	});
	       };


	resm.start = function() {

                     //  Here it is not needed to use round robin over all the available ports:
                     //     - So it is using the function 'db.client' instead of 'db.client_with_index'
		var  db_client = db.client();

		/**
        	 * It checks the database connection and starts the Worker if it is OK
        	**/
		db_client.connect(function(err) {

			db_client.end();
			db_client = null;

                	if(err) {

				logger.log_err(logger.logger, place, 'start', 1, err, 'Error while trying to connect to the database');
			
                        	// Terminate the worker server with error
                        	process.exit(1);

                	} else {

				// Useful resources about errors:
                                //    - https://www.joyent.com/developers/node/design/errors
                                //         - They are using:
                                //              - https://github.com/davepacheco/node-verror
                                // ---
				// It is useful as a debugging tool (until the app is stabilized)
				process.on('uncaughtException', function(err) {
  				
					logger.log_err(logger.logger, place, 'start', 2, err.stack || err, 'Mmmh, an uncaught exception, the application is not stable ..');

					 // As the exception was not managed, the application is in an undefined state, so it is ending the worker server with error
                                	process.exit(1);
				});


                        	// Start the Worker
                        	worker_start();
                	}
        	});
	};

	
	return resm;
};
