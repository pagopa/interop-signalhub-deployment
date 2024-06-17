#!/bin/bash
set -euo pipefail

. $(dirname "$0")/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute kubectl diff
        [ -j | --job ] Cronjob defined in jobs folder
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
job=""
enable_debug=false
post_clean=false
skip_dep=false

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
        -sd | --skip-dep)
          skip_dep=true
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

if [[ -z $environment || $environment == "" ]]; then
  echo "Environment cannot be null"
  help
fi
if [[ -z $job || $job == "" ]]; then
  echo "Job cannot null"
  help
fi
if [[ $skip_dep == false ]]; then
  bash $(dirname "$0")/helmDep.sh
fi

VALID_CONFIG=$(isCronjobEnvConfigValid $job $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "Environment configuration '$environment' not found for cronjob '$job'"
  help
fi

ENV=$environment
OUT_DIR="./out/templates/$ENV/cron_$job"
OUT_DIR=$( echo $OUT_DIR | sed  's/-/_/g' )
#rm -rf $OUT_DIR
#mkdir  -p $OUT_DIR

DIFF_CMD="kubectl diff --show-managed-fields=false -f "
#if [[ $enable_debug == true ]]; then
#    DIFF_CMD=$DIFF_CMD"--debug "
#fi

DIFF_CMD=$DIFF_CMD" $OUT_DIR/$job.out.yaml"

eval $DIFF_CMD
#if [[ $post_clean == true ]]; then
#  rm -rf $OUT_DIR
#fi
