
#
# Utilities functions to be used with the scripts starting the application 's containers for test
#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#


#
# It receives 1 optional argument:
#    1. The IP of a peer in the Weave Network:
#          - See more at:
#               - https://www.weave.works/docs/net/latest/using-weave
#               - https://www.weave.works/docs/net/latest/using-weave/finding-adding-hosts-dynamically
# 
function enable_weave() {

	# Check if Weave is active, otherwise launch it
	local WS=$(weave status 2>&1)
	local WS2=$(echo $WS | grep 'weave container is not running')
	if [[ "$WS2" == *"weave container is not running"* ]]; then
        	echo
        	echo "Weave is not active, launching it .. "
        	echo

		# Check if the IP of a peer was given
		if [ -z "$1" ]; then
        		weave launch
		else
			weave launch "$1"
		fi
	fi

	# Enable the container to attach to the Weave Proxy
	echo
        echo "Enabling the Weave Proxy .. "
        echo
	eval $(weave env)
}


#
# It receives 2 mandatory arguments:
#    1. Volume name
#    2. If delete an existing volume ('y') or not ('n')
#
function enable_volume() {

	# Check if the volume exits
	local DO=$(docker volume inspect $1 2>&1)
        local DO2=$(echo $DO | grep 'No such volume')
        if [[ "$DO2" == *"No such volume"* ]]; then
        	# The volume does not exists
		echo
		echo "Creating the volume: $1 .."
		echo
                local RES=$(docker volume create --name "$1")
        else
        	# The volume already exists
              	if [ "$2" == "y" ]; then
			echo
                        echo "Deleting the volume: $1 .."
                        echo
                      	local RES=$(docker volume rm "$1")

			echo
                	echo "Creating the volume: $1 .."
                	echo
                      	RES=$(docker volume create --name "$1")
                fi
	fi
}

