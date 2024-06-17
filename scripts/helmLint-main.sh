#!/bin/bash
set -euo pipefail

echo "Running helm lint process"

SCRIPTS_FOLDER=$(dirname "$0")
. $SCRIPTS_FOLDER/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to detect values.yaml for linting
        [ -d | --debug ] Enable Helm template debug
        [ -m | --microservices ] Lint all microservices
        [ -j | --jobs ] Lint all cronjobs
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print linting output on terminal
        [ -c | --clean ] Clean files and directories after scripts successfull execution
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
enable_debug=false
lint_microservices=false
lint_jobs=false
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
        -m | --microservices )
          lint_microservices=true
          step=1
          shift 1
          ;;
        -j | --jobs )
          lint_jobs=true
          step=1
          shift 1
          ;;
        -d | --debug)
          enable_debug=true
          step=1
          shift 1
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
        -c | --clean)
          post_clean=true
          step=1
          shift 1
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
echo "Environment: $environment"

ENV=$environment
DELIMITER=";"
MICROSERVICES_DIR="$(pwd)/microservices"
CRONJOBS_DIR="$(pwd)/jobs"

OPTIONS=" "
if [[ $enable_debug == true ]]; then
  OPTIONS=$OPTIONS" -d"
fi
if [[ $post_clean == true ]]; then
  OPTIONS=$OPTIONS" -c"
fi
if [[ -n $output_redirect ]]; then
  OPTIONS=$OPTIONS" -o $output_redirect"
fi
if [[ $skip_dep == false ]]; then
  bash $SCRIPTS_FOLDER/helmDep.sh --untar
fi
# Skip further execution of helm deps build and update since we have already done it in the previous line 
OPTIONS=$OPTIONS" -sd"


if [[ $lint_microservices == true ]]; then
  echo "Start linting microservices"
  for dir in "$MICROSERVICES_DIR"/*;
  do
    CURRENT_SVC=$(basename "$dir");
    echo "Linting $CURRENT_SVC"
    VALID_CONFIG=$(isMicroserviceEnvConfigValid $CURRENT_SVC $ENV)
    if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
      echo "Environment configuration '$ENV' not found for microservice '$CURRENT_SVC'. Skip"
    else
      $SCRIPTS_FOLDER/helmLint-svc-single.sh -e $ENV -m $CURRENT_SVC $OPTIONS
    fi
  done
fi

if [[ $lint_jobs == true ]]; then
  echo "Start linting cronjobs"
  for dir in "$CRONJOBS_DIR"/*;
  do
    CURRENT_JOB=$(basename "$dir");
    echo "Linting $CURRENT_JOB"
    VALID_CONFIG=$(isCronjobEnvConfigValid $CURRENT_JOB $ENV)
    if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
      echo "Environment configuration '$ENV' not found for cronjob '$CURRENT_JOB'"
    else
      $SCRIPTS_FOLDER/helmLint-cron-single.sh -e $ENV -j $CURRENT_JOB $OPTIONS
    fi
  done
fi


if [[ $post_clean == true ]]; then
  rm -rf $(pwd)/out/lint
fi
