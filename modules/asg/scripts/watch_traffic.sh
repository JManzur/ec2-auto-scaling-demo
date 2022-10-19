#!/bin/bash

source_env () {
    set -e
    set -a
    source .env
}

source_env

while true; do echo -n; curl -s $ALB_FQDN | jq -r; sleep 2; done