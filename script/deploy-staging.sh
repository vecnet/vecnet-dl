#!/usr/bin/env bash

# Invoked by the CurateND-Integration Jenkins project
# Setup and run capistrano to deploy the preproduction application and workers
#
# This runs on the same host as jenkins
#
# called from Jenkins command
#       Build -> Execute Shell Command ==
#       test -x $WORKSPACE/script/deploy-staging.sh && $WORKSPACE/script/deploy-staging.sh
echo "=-=-=-=-=-=-=-= start $0"

source $WORKSPACE/script/common-deploy.sh

do_deploy staging
