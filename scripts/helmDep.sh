#!/bin/bash
set -euo pipefail

help()
{
    echo "Usage: 
        [ -u | --untar ] Untar downloaded charts
        [ -v | --verbose ] Show debug messages
        [ -h | --help ] This help" 
    exit 2
}


args=$#
untar=false
step=1
verbose=false

for (( i=0; i<$args; i+=$step ))
do
    case "$1" in
        -u| --untar )
          untar=true
          step=1
          shift 1
          ;;
        -v| --verbose )
          verbose=true
          step=1
          shift 1
          ;;
        -h | --help )
          help
          ;;
        *)
          echo "Unexpected option: $1"
          help

          ;;
    esac
done

function setupHelmDeps() 
{
    untar=$1
    
    rm -rf charts
    echo "# Helm dependencies setup #"
    echo "-- Add PagoPA eks repos --"
    helm repo add interop-eks-microservice-chart https://pagopa.github.io/interop-eks-microservice-chart > /dev/null
    helm repo add interop-eks-cronjob-chart https://pagopa.github.io/interop-eks-cronjob-chart > /dev/null

    echo "-- Update PagoPA eks repo --"
    helm repo update interop-eks-microservice-chart > /dev/null
    helm repo update interop-eks-cronjob-chart > /dev/null

    if [[ $verbose == true ]]; then
        echo "-- Search PagoPA charts in repo --"
    fi
    helm search repo interop-eks-microservice-chart > /dev/null
    helm search repo interop-eks-cronjob-chart > /dev/null

    if [[ $verbose == true ]]; then
        echo "-- List chart dependencies --"
    fi
    helm dep list | awk '{printf "%-35s %-15s %-20s\n", $1, $2, $3}'
    
    if [[ $verbose == true ]]; then
        echo "-- Build chart dependencies --"
    fi
    # only first time
    #helm dep build 
    dep_up_result=$(helm dep up)
    if [[ $verbose == true ]]; then
        echo $dep_up_result
    fi

    if [[ $untar == true ]]; then
        cd charts
        for filename in *.tgz; do 
            tar -xf "$filename" && rm -f "$filename";
        done;

        cd ..
    fi

    echo "-- Helm dependencies setup ended --"
    exit 0
}


setupHelmDeps $untar