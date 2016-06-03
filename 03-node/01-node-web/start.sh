#!/bin/bash

#
# Author:
#    - Jorge Couchet <jorge.couchet@gmail.com>
#


# Installing the needed application modules
( cd /opt/nodeapp ; npm install )

# Starting supervisor
/usr/bin/supervisord --config /etc/supervisor/conf.d/supervisor.conf
