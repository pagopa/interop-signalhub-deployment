#!/bin/bash
set -euo pipefail

SCRIPTS_FOLDER=$(dirname "$0")
. $SCRIPTS_FOLDER/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute kubectl diff
        [ -d | --debug ] Enable debug
        [ -j | --job ] Cronjob defined in jobs folder
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
job=""
enable_debug=false
post_clean=false
output_redirect=""
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
        -d | --debug)
          enable_debug=true
          step=1
          shift 1
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
        -o | --output)
          [[ "${2:-}" ]] || "When specified, output cannot be null" || help
          output_redirect=$2
          if [[ $output_redirect != "console" ]]; then
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
  bash $SCRIPTS_FOLDER/helmDep.sh
fi

VALID_CONFIG=$(isCronjobEnvConfigValid $job $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "Environment configuration '$environment' not found for cronjob '$job'"
  help
fi

ENV=$environment
OPTIONS=" "
if [[ $enable_debug == true ]]; then
  OPTIONS=$OPTIONS" -d"
fi
if [[ -n $output_redirect ]]; then
  OPTIONS=$OPTIONS" -o $output_redirect"
fi

HELM_TEMPLATE_CMD="$SCRIPTS_FOLDER/helmTemplate-cron-single.sh -e $ENV -j $job $OPTIONS"
APPLY_CMD="kubectl apply --show-managed-fields=false -f -"

eval $HELM_TEMPLATE_CMD" | "$APPLY_CMD