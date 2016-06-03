#!/bin/bash

#
# It run the indicated stress tool with the given paramenters:
#    - In order to run it:
#         - ./start_stest.sh wrk 3 16 http://localhost/upload [WRK_REMAINING_PARAMS]
#              - All the 'wrk' parameters are accepted with the exception of:
#                   - '-s'
#                   - the target to test
#         - ./start_stest.sh ab 1000 8 http://localhost/upload [AB_REMAINING_PARAMS]
#              - All the 'ab' parameters are accepted with the exception of:
#                   - '-T'
#                   - '-H'
#                   - '-p'
#                   - the target to test
#
#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#


# The current script expects 5 mandatory arguments
NUMBER_MANDATORY_ARGUMENTS=5

# Check the number of arguments received and that they are not empty
if [ "$#" -lt "$NUMBER_MANDATORY_ARGUMENTS" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo 
        echo "It is needed:"
        echo "  1. The name of the stress tool to run"
        echo "  2. The number of lines for the CSV test file to be generated"
        echo "  3. The amount of characters to be used for first name, surname and domain in the CSV file to be generated"
        echo "  4. If generate the CSV test file, otherwise it is used the test file at: test_files/test.csv"
        echo "  5. The target to test, such as: http://localhost/upload ..."
        echo

        # Finishes the current script
        exit 1
fi

if [ $4 == "y" ] || [ $4 == "Y" ]; then

	# Generate the CSV test file
	./create_file.py -f test_files/test.csv -l "$2" -s "$3"
fi

# Encode the CSV test file with the multipart format
./encode_rfc1867.py -i test_files/test.csv -o test_files/test.txt

# Check which stress tool to run
if [ $1 == "wrk" ]; then

	if [ "$#" -eq "$NUMBER_MANDATORY_ARGUMENTS" ]; then

		# Using default arguments:
                #    - Running 600 seconds with 5 threads with 25 concurrent connections
		wrk -t5 -c25 -d600s -s post.lua "$5"

	else
	
		wrk "${@:6}" -s post.lua "$5"
	fi

else

	if [ "$#" -eq "$NUMBER_MANDATORY_ARGUMENTS" ]; then

		# Using default arguments:
                #    - Running 2.000 seconds with a rate of 25 requests per second:
                #         - In fact 'ab' is doing 50.000 requests, if the application processes the requests very fast, then the test will run less than 2.000 seconds
		ab -t 2000 -T 'multipart/form-data; boundary=---------------------------126474506989943511588532701' -H 'Accept-Encoding: gzip,deflate' -p test_files/test.txt "$5" 

	else
		
		ab "${@:6}" -T 'multipart/form-data; boundary=---------------------------126474506989943511588532701' -H 'Accept-Encoding: gzip,deflate' -p test_files/test.txt "$5"
	fi
fi
