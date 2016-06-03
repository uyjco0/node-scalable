
/**
 *
 * The application entry point:
 *    - Usage:
 *         - node start.js [web | worker] [y | n]
 *              - By using the optional argument 'web' or 'worker'
 *                it is decided which kind of process to start
 *              - By using the optional argument 'y' or 'n', it is
 *                dedided if the process is started with memory
 *                profiling or not
 *
 * @author Jorge Couchet <jorge.couchet@gmail.com>
 *
 *
**/


var   config = require('./config')

    , logger = require('./lib/logger.js')(config)

    , db = require('./lib/db.js')(config, logger)

    , option = null

       // It is useful for memory leak detection
    , heapdump = null
    , memwatch = null
    , max_snapshots = 0;



/**
 ***************************
 ***** MEMORY PROFILING ****
 ***************************
**/

if (process.argv.length >= 3) {

        // Observations regard the memory leak problem:
        //    - Garbage Collection (GC) is a costly process, so V8 frees memory only as soon as there is not enough memory left:
        //         - So if for example the application is running with only 1GB of RAM, and by default Node.js is declaring that
        //           will use 1.4GBs of RAM:
        //              - Then in this setting the GC is not starting to collect unreferenced objects (i.e. the GC is not freeing 
        //                memory at all):
        //                   - So, this scenario is not a case of memory leak, but what we need to do is to start Node.js with the
        //                     option '--max_old_space_size' in order to declare the right amount the memory it will use
        //    - Some things to do in order to avoid memory leaks:
        //         - http://www.ibm.com/developerworks/library/wa-use-javascript-closures-efficiently/index.html
        // ---
        // Check if it is needed to start the memory profiling process
	if ((process.argv[2].toLowerCase() == 'y') || ((process.argv.length >= 4) && (process.argv[3].toLowerCase() == 'y'))) {

		// It loads the needed modules
		heapdump = require('heapdump');
		memwatch = require('memwatch-next');
		
		// It takes an initial snapshot
		heapdump.writeSnapshot(config.log_folder + '/dump-'  + process.env.INSTANCE_NAME + '-' + Date.now() + '.heapsnps');

		// It take a snapshot when receiving a 'leak' event
                //    - These snapshots can be later analyzed with Google Chrome, and compared between them using the 'Comparison' tab.
		memwatch.on('leak', function(info) {

			logger.log_err(logger.logger, place, 'main', 1, '', 'Possible memory leak detected: ', info);

			if ( max_snapshots < config.max_snapshots) {

				heapdump.writeSnapshot(config.log_folder + '/dump-'  + process.env.INSTANCE_NAME + '-' + Date.now() + '.heapsnps');

				++max_snapshots;
			}
		});
	}
}



/**
 ******************************************
 ***** STARTING WEB SERVICES / WORKERS ****
 ******************************************
**/

// It checks if it is needed to start as a Node.js based Worker
if (process.argv.length >= 3) {

	if (process.argv[2].toLowerCase() == 'worker') {

		option = require('./lib/worker.js')(config, logger, db);

	} else {

		option = require('./lib/web.js')(config, logger, db);
	}

} else {

	// The default option is to start as a Node.js based
        // Web service
	option = require('./lib/web.js')(config, logger, db);
} 

// It starts the selected option
option.start();
