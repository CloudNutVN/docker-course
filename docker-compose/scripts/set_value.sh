#!/bin/bash

if [[ $# -ne 1 ]]; then
    (>&2 echo "Usage: $0 VALUE")
    exit 1
fi

DOCKER_MACHINE_IP=$(docker-machine ip default)
DOCKER_WEBSERVICE_PORT=$(docker-compose port webservice 8080 | cut -d ":" -f2)

DATA="{\"value\": \"${1}\"}"

curl -X POST -H "Content-Type: application/json" -d "$DATA" "http://${DOCKER_MACHINE_IP}:${DOCKER_WEBSERVICE_PORT}/value"