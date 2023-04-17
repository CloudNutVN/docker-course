#!/bin/bash 

set -e

DOCKER_MACHINE_HOST=$(docker-machine ip default)
DOCKER_WEBSERVICE_PORT=$(docker-compose port webservice 8080 | cut -d ":" -f2)

curl "http://${DOCKER_MACHINE_HOST}:${DOCKER_WEBSERVICE_PORT}/value"