
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate a Docker STEST image:
      - The image is able to run the strss tools:
           - 'ab':
                - https://httpd.apache.org/docs/2.4/programs/ab.html  
           - 'wrk':
                - https://github.com/wg/wrk 



****** SOURCES ******************

-> It is custom code



******* NEEDED ******************

> The 'weave' app should be already started:
      - Check it with:
           - weave status
      - If it is not started:
           - weave launch
      - Make available the weave proxy for the containers:
           - eval $(weave env)



******* GENERATE THE STEST IMAGE ******************

-> The command to build the image from the Dockerfile is:
      - docker build -t uyjco0/stest:01 .



******* USING THE STEST IMAGE ******************

-> There are several ways:
      - Running 'ab':
           - docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 ab 5 16 y http://webg1.weave.local/upload -n 1 -c 1
           - docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 ab 5 16 y http://webg1.weave.local/upload
           - docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01
      - Running 'wrk':
           - docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 wrk 5 16 y http://webg1.weave.local:80/upload -t1 -c1 -d1s
                - Not adding the port (i.e. ':80') gives the following error:
                     - 'Servname not supported for ai_socktype'
           - docker run -it --rm --name stest1 -e INSTANCE_NAME=stest1 -v node-scalable/06-test/01-stest/stest:/opt/stest:rw uyjco0/stest:01 wrk 5 16 y http://webg1.weave.local:80/upload



******* CONFIG FILES USED IN THE STEST IMAGE ******************

-> post.lua:
      - It is a Lua script used to configure the 'wrk' running:
           - See more at:
                - https://github.com/wg/wrk/blob/master/SCRIPTING
