#!/bin/bash
#
# Author: Andre Ferreira <andre.dev.linux@gmail.com>
# Date..: 23/04/2023
#
# tools:
#   - Java 11+: (Install) 
#       sdkman    -> https://sdkman.io/install
#   - maven: 
#       (Install) -> https://maven.apache.org/install.html
#   - docker: 
#       (Install) -> https://docs.docker.com/engine/install/
#   - docker-compose: 
#       (Install) -> https://docs.docker.com/compose/install/


PROJECTS=("mc-composer-reactive" "mc-products" "mc-assessments")

for PROJECT in "${PROJECTS[@]}" 
do
    if [ ! -d "$PROJECT" ]; then
        echo "Cloning project... $PROJECT"
        git clone https://github.com/andrelsf/"$PROJECT".git
    fi
done

docker-compose up -d