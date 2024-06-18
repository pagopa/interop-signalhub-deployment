#!/bin/bash
set -euo pipefail

function isCronjobEnvConfigValid()
{
    CRONJOB=$1
    ENVIRONMENT=$2
    CRONJOBS_DIR=$(getCronjobsDir)

    if [[ ! -d "$CRONJOBS_DIR/$CRONJOB/$ENVIRONMENT" ]]; then
        echo ""
    else
        echo "true"
    fi
}

function isMicroserviceEnvConfigValid()
{
    MICROSERVICE=$1
    ENVIRONMENT=$2
    MICROSERVICE_DIR=$(getMicroservicesDir)

    if [[ ! -d "$MICROSERVICE_DIR/$MICROSERVICE/$ENVIRONMENT" ]]; then
        echo ""
    else
        echo "true"
    fi
}

function getCronjobsDir()
{
    echo "./jobs"
}

function getMicroservicesDir()
{
    echo "./microservices"
}

function getAllowedMicroservices()
{
    local DELIMITER=";"
    local SERVICES_DIR=./microservices
    local ALLOWED_SERVICES=""

    for dir in $SERVICES_DIR/*;
    do
        CURRENT_SVC=$(basename "$dir");
        if [[ $ALLOWED_SERVICES == "" ]]; then
            ALLOWED_SERVICES=$CURRENT_SVC
        else
            ALLOWED_SERVICES=$ALLOWED_SERVICES$DELIMITER$CURRENT_SVC
        fi
    done

    echo $ALLOWED_SERVICES
}


function getAllowedCronjobs()
{
    local DELIMITER=";"
    local CRONJOBS_DIR=./jobs
    local ALLOWED_CRONJOBS=""

    for dir in $CRONJOBS_DIR/*;
    do
        CURRENT_JOB=$(basename "$dir");
        if [[ $ALLOWED_CRONJOBS == "" ]]; then
            ALLOWED_CRONJOBS=$CURRENT_JOB
        else
            ALLOWED_CRONJOBS=$ALLOWED_CRONJOBS$DELIMITER$CURRENT_JOB
        fi
    done

    echo $ALLOWED_CRONJOBS
}

function isAllowedValue()
{
    local LIST=$1
    local DELIMITER=$2
    local VALUE=$3
    local RESULT=$(echo $LIST | tr "$DELIMITER" '\n' | grep -i $VALUE)
    echo $RESULT
}

function isAllowedMicroservice()
{
    local ALLOWED_SERVICES=$(getAllowedMicroservices)
    local DELIMITER=";"
    local SERVICE=$1
    local RESULT=$(isAllowedValue $ALLOWED_SERVICES $DELIMITER $SERVICE)
    
    if [[ -z $RESULT || $RESULT == "" ]]; then
        echo ""
    else
        echo "true"
    fi
}

function isAllowedCronjob()
{
    local ALLOWED_CRONJOBS=$(getAllowedCronjobs)
    local DELIMITER=";"
    local CRONJOB=$1
    local RESULT=$(isAllowedValue $ALLOWED_CRONJOBS $DELIMITER $CRONJOB)
    
    if [[ -z $RESULT || $RESULT == "" ]]; then
        echo ""
    else
        echo "true"
    fi
}