
******* AUTHOR ****************

-> Jorge Couchet <jorge.couchet@gmail.com>



******* GOAL ******************

-> Here are the instructions to generate the utility 'docker-edit-properties':
      - It is used in the Dockerfile in order to edit in easy way a configuration file


******* SOURCES ******************

-> It is reusing (but modified) code from:
      - https://github.com/confluentinc/docker-images


******* GENERATE THE NEEDED UTILITY ******************

-> Steps:
      1. Install Maven:
            - sudo apt-get install maven

      2. Test installation:
            - mvn -version

      3.  Modification to the 'pom.xml':
             - I deleted the licence pluging:
                  - <plugin>
             	       <groupId>com.mycila</groupId>
                      <artifactId>license-maven-plugin</artifactId>
                      ...
                      </executions>
                    </plugin>

      4. Command line build (in the folder with the 'pom.xml'):
            - mvn clean install
            - Obs:
                 - The compiled 'jar' file is in the 'target' folder:
                      - The name is:
                           - docker-utils-1.0.0-SNAPSHOT.jar

      5. Copy the generated 'jar' files to the 'utils/docker-utils' folder:
            - cp -r target/docker-utils-1.0.0-SNAPSHOT-package/share/java/docker-utils/ .
                 - The folder 'docker-utils' is having the 'jar' files for all the
                   'docker-edit-properties' dependencies
