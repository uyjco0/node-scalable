
/**
 *
 * The functions to be used by the Node.js based Web service (i.e. 'node-web').
 *
 * @author Jorge Couchet <jorge.couchet@gmail.com>
 *
 *
**/

module.exports = function(config, logger, db) {

	var     resm = { start: null }

              , place = 'lib/web.js'

              , http = require('http')

              , busboy = require('busboy')

              , server

	        /**
		* It displays a barebone form
		**/
	      , display_form = function(req, res) {

			res.writeHead(200, { Connection: 'close' });

			res.end('<html><head></head><body>' +
				'<form method="POST" enctype="multipart/form-data">' +
                		'<input type="file" name="filefield"><br />' +
                		'<input type="submit">' +
              			'</form>' +
            			'</body></html>'
			);
		}

		/**
                * It returns a JSON object to the client with the result form the API call:
                *  -> msg = 1 && fname = '' : The HTTP method was wrong
                *  -> msg = 2 && fname = '' : The API entry point was wrong
                *  -> msg = 3 && fname = file_name : There was a problem with the database
                *  -> msg = 4 && fname = file_name : The server was processing
                *  -> msg = 5 && fname = '' : There was not a file name
                **/
              , display_msg = function(req, res, msg, fname) {

                        var headc = 200;

                        if (msg == 1 || msg == 2) {

                                headc = 404
                        }

                        res.writeHead(headc, { 'Connection': 'close', 'Content-Type': 'application/json' });

                        res.end(JSON.stringify({ 'msg': msg, 'fname': fname }));
                }

	        /**
	        * It uploads by streaming a file from the client to the database
	        **/
	      , upload_file = function(req, res) {

			      // Create a writable stream
                	var   bboy = new busboy({ headers: req.headers });
		

			bboy.on('file', function(fieldname, file, filename, encoding, mimetype) {
     
				var   db_client = null
				    , stream_db = null;
 
				if (filename != '') {

					//  Here it is not needed to use round robin over all the available ports:
                     			//     - So it is using the function 'db.client' instead of 'db.client_with_index'
					db_client = db.client();

					// In a standard query the connection is closed with a explicit call in
                                        // the query 's callback to its 'end' method:
                                        //    - Here that is not possible because it is being used 'pg-copy-streams'
                                        //      with the query. But still it is needed to close the database
                                        //      connections as fast as possible to avoid issues with the 
                                        //      'PgBouncer' 's parameter 'max_client_conn'
					db_client.on('drain', function(){

						db_client.end()
                                              	db_client = null;
					});

					db_client.connect(function(err) {

						if (err) {

							db_client.end();
							db_client = null;
							
							// Some of the error sources are:
                                                        //    1. The database is down
                                                        //    2. The pooling service is down
                                                        //    3. The amount of users trying to connect to the database are greater than the PgBouncer 's parameter 'max_client_conn'
							logger.log_err(logger.logger, place, 'upload_file', 1, err, 'Error while trying to connect to the database in order to load the file: ' + filename);

							// Just to discard the contents from the readable stream 'file'
                                			file.resume();

							file = null;	

							return display_msg(req, res, 3, filename);

						} else {

							// Create a writable stream to the database
                                                        // --
							// // Copy the CSV file to the table 'csvs' using the columns 'name' and 'email'
							stream_db = db_client.query(db.pgc("COPY csvs (name, email) FROM STDIN WITH DELIMITER ',' csv"));

							stream_db.on('error', function(err) {

								logger.log_err(logger.logger, place, 'upload_file', 2, err, 'Error with writable stream to the database');
							})
							
							stream_db.on('finish', function() {

								// Trying to help the Garbage Collector (GC) with its task, and thus avoiding memory leaks:
                                                                //    - Source:
                                                                //         - http://www.ibm.com/developerworks/library/wa-use-javascript-closures-efficiently/index.html

								file.unpipe();

								file = null;

								stream_db = null;

								return display_msg(req, res, 4, filename);
                                                	})

							// Send the file stream to the database
							file.pipe(stream_db);
						}
					});

				} else {

					logger.log_err(logger.logger, place, 'upload_file', 3, '', 'There was not a file name');

					// Just to discard the contents
					file.resume();

					file = null;

					return display_msg(req, res, 5, '');
				}
    			});

			bboy.on('error', function(err) {

                        	logger.log_err(logger.logger, place, 'upload_file', 4, err, 'Error with the busboy stream');
                        });

			bboy.on('finish', function() {

				bboy = null;
			});

			// Start to process the file with 'busboy'	
    			req.pipe(bboy);		
		}

		  /**
		  * Event listener for HTTP server "error" event.
		  */
		, onError = function(err) {

			logger.log_err(logger.logger, place, 'onError', 1, err, 'Unexpected error on the server, shutting down');

			// Terminate the Web service with error
			process.exit(1);
		}

	 	  /**
		  * Event listener for HTTP server "listening" event.
		  */
		, onListening = function() {

			var port = config.httpServerPort || process.env.PORT

			logger.log_info(logger.logger, place, 'onListening', 1, 'Server started at port: ' + port);
		}

		  /**
		  * It creates a server with a barebone router (for performance).
		  **/
		, create_server = function() {

			return http.createServer(function(req, res) {

        			// The API entry point
        			if (req.url === '/upload') {

                			if (req.method === 'GET') {

                        			display_form(req, res);

                			} else {

                        			if (req.method === 'POST') {

                                			upload_file(req, res);

                        			} else {

                                			display_msg(req, res, 1, '');
                        			}
                			}

        			} else {

                			display_msg(req, res, 2, '');
        			}

			});
		}

	      , shutdown = function () {

			logger.log_info(logger.logger, place, 'shutdown', 1, 'Server stopped');

			// Terminate the Web service
        		process.exit();
	        };


	resm.start = function() {

		     //  Here it is not needed to use round robin over all the available ports:
                     //     - So it is using the function 'db.client' instead of 'db.client_with_index'
		var db_client = db.client();

		/**
        	* It tests the database connection and starts the Web service if it is OK.
        	**/
		db_client.connect(function(err) {

			db_client.end();
                       	db_client = null;

                	if(err) {

				logger.log_err(logger.logger, place, 'start', 1, err, 'Error while trying to connect to the database');

                        	// Terminate the Web service with error
                        	process.exit(1);

                	} else {

                        	// Create the http server
                        	server = create_server();

				 // Listen on provided port, on all network interfaces
                		server.listen(config.httpServerPort || process.env.PORT);

				server.on('error', onError);

				// Emitted when the server has been bound after calling server.listen
                		// -> https://nodejs.org/api/net.html#net_event_listening
                		server.on('listening', onListening);

                        	// Handle web server gentle shutdown
                        	process.on('SIGTERM', shutdown);
                	}
        	});
	};

	return resm;
};
