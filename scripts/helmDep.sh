#!/bin/bash
set -euo pipefail

help()
{
    echo "Usage: 
        [ -u | --untar ] Untar downloaded charts
        [ -h | --help ] This help"
    exit 2
}


args=$#
untar=false
step=1

for (( i=0; i<$args; i+=$step ))
do
    case "$1" in
        -u| --untar )
          untar=true
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

    echo "-- Add repo --"
    helm repo add interop-eks-microservice-chart https://pagopa.github.io/interop-eks-microservice-chart
    helm repo add interop-eks-cronjob-chart https://pagopa.github.io/interop-eks-cronjob-chart

    echo "-- Update repo --"
    helm repo update interop-eks-microservice-chart
    helm repo update interop-eks-cronjob-chart

    echo "-- Search charts in repo --"
    helm search repo interop-eks-microservice-chart
    helm search repo interop-eks-cronjob-chart

    echo "-- List chart dependencies --"
    helm dependency list
    echo "-- Build chart dependencies --"
    # only first time
    # todo
    helm dep up 
    #helm dep build 
    # echo "-- Update chart dependencies --"

    if [[ $untar == true ]]; then
        cd charts
        for filename in *.tgz; do 
            tar -xf "$filename" && rm -f "$filename";
        done;

        cd ..
    fi

    echo "-- Dependency setup ended --"
    exit 0
}


setupHelmDeps $untar