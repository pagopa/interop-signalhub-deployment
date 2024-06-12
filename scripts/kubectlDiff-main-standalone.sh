#!/bin/bash
set -euo pipefail

echo "Running kubectl diff process"

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to execute kubectl diff
        [ -d | --debug ] Enable debug
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -m | --microservices ] Execute diff for all microservices
        [ -j | --jobs ] Execute diff for all cronjobs
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
enable_debug=false
template_microservices=false
template_jobs=false
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
        -m | --microservices )
          template_microservices=true
          step=1
          shift 1
          ;;
        -j | --jobs )
          template_jobs=true
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
MICROSERVICES_DIR=./microservices
CRONJOBS_DIR=./jobs

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
  bash $(dirname "$0")/helmDep.sh
fi
# Skip further execution of helm deps build and update since we have already done it in the previous line 
OPTIONS=$OPTIONS" -sd"


if [[ $template_microservices == true ]]; then
  echo "Start microservices templates diff"
  for dir in $MICROSERVICES_DIR/*;
  do
    CURRENT_SVC=$(basename "$dir");
    echo "Diff $CURRENT_SVC"
    ./kubectlDiff-svc-single-standalone.sh -e $ENV -m $CURRENT_SVC $OPTIONS
  done
fi

if [[ $template_jobs == true ]]; then
  echo "Start cronjobs templates diff"
  for dir in $CRONJOBS_DIR/*;
  do
    CURRENT_JOB=$(basename "$dir");
    echo "Diff $CURRENT_JOB"
    ./kubectlDiff-cron-single-standalone.sh -e $ENV -j $CURRENT_JOB $OPTIONS
  done
fi
