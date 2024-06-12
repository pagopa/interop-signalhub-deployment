#!/bin/bash
set -euo pipefail

. $(dirname "$0")/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used for image version search
        [ -m | --microservice ] Microservice defined in microservices folder. Cannot be used in conjunction with "job" option
        [ -j | --job ] Cronjob defined in jobs folder. Cannot be used in conjunction with "microservice" option
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
microservice=""
job=""

step=1
for (( i=0; i<$args; i+=$step ))
do
    case "$1" in
        -e| --environment )
            [[ "${2:-}" ]] || "Environment cannot be null" || help

          environment=$2
          step=2
          shift 2
          ;;
        -m | --microservice )
          [[ "${2:-}" ]] || "Microservice cannot be null" || help

          microservice=$2
          serviceAllowedRes=$(isAllowedMicroservice $microservice)
          if [[ -z $serviceAllowedRes || $serviceAllowedRes == "" ]]; then
            echo "$microservice is not allowed"
            echo "Allowed values: " $(getAllowedMicroservices)
            help
          fi

          step=2
          shift 2
          ;;
        -j | --job )
          [[ "${2:-}" ]] || "Job cannot be null" || help
          
          job=$2
          jobAllowedRes=$(isAllowedCronjob $job)
          if [[ -z $jobAllowedRes || $jobAllowedRes == "" ]]; then
              echo "$job is not allowed"
              echo "Allowed values: " $(getAllowedCronjobs)
              help
          fi

          step=2
          shift 2
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

if [[ -z $environment || $environment == "" ]]; then
  echo "Environment cannot be null"
  help
fi

if [[ -z $microservice || $microservice == "" ]] && [[ -z $job || $job == "" ]]; then
  echo "At least ine from microservice and job option should be set"
  help
fi

if [[ -n $microservice ]] && [[ -n $job ]]; then
  echo "Only one from microservice and job option should be set"
  help
fi

target=""
tagetValues=""
tag_placeholder="IMAGE_TAG_PLACEHOLDER"
digest_placeholder="IMAGE_DIGEST_PLACEHOLDER"

suffix="_IMAGE_VERSION"
digestSuffix="_IMAGE_DIGEST"

prefix=""

if [[ -n $microservice ]]; then
  target=$microservice
  tagetValues="values-microservice"
else
  target=$job
  tagetValues="values-cronjob"
  prefix="JOB_"
fi

target=$(echo $target | sed  's/-/_/g' | tr '[a-z]' '[A-Z]')
targetRegex=$prefix$target$suffix

found_version=$(cat ./commons/$environment/values-images.sh | { egrep -i  "^$targetRegex" || :; } )
if [[ -n $found_version ]]; then
  found_version=$(echo $found_version | cut -d '=' -f 2)
  #echo "Found version $found_version for $target"
fi

digestTargetRegex=$prefix$target$digestSuffix
found_digest=$(cat ./commons/$environment/values-images.sh | { egrep -i  "^$digestTargetRegex" || :; } )
if [[ -n $found_digest ]]; then
  found_digest=$(echo $found_digest | cut -d '=' -f 2)
  #echo "Found digest $found_digest for $target"
fi

export $tag_placeholder=$found_version
export $digest_placeholder=$found_digest

envsubst < ./commons/$environment/$tagetValues.yaml > ./commons/$environment/$tagetValues.compiled.yaml