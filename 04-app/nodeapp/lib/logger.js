
/**
 *
 * Logger for the modules using singleton pattern.
 *
 * @author Jorge Couchet <jorge.couchet@gmail.com>
 *
 *
**/

    // singleton
var logger = null;

module.exports = function(config) {

	var   bunyan = null

    	    , bunyanOpts = null

	    , fname = '';


    	if (!logger) {

		fname = (process.env.INSTANCE_NAME || config.instance_name);

		bunyan = require('bunyan');

		bunyanOpts = {

                	  'name': fname

                	, 'streams': [
                			{
                			    'level': 'info'

                		          , 'path': config.log_folder + '/' + fname + '.log'
                		        }
                	]
            	};

    		logger = {
                	     'logger': bunyan.createLogger(bunyanOpts)

			   , 'log_err': function(logger, place, fplace, pos, err, msg) {

                             			logger.error({   'place': place + ' - ' + fplace + ' - ' + pos
                                       		                , 'error': err
                                     		     	     } 
                                                             , msg
                        			);
				        }

			   , 'log_info': function(logger, place, fplace, pos, msg) {

                                                logger.info({ 'place': place + ' - ' + fplace + ' - ' + pos }
                                                             , msg
                                                );
                                         }
                }

 	}

	return logger;
};
