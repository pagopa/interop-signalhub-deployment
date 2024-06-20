#!/bin/bash
set -euo pipefail


SCRIPTS_FOLDER=$(dirname "$0")
. $SCRIPTS_FOLDER/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used for template generation
        [ -d | --debug ] Enable Helm template debug
        [ -j | --job ] Cronjob defined in jobs folder
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -c | --clean ] Clean files and directories after script successfull execution
        [ -v | --verbose ] Show debug messages
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
verbose=false

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
JOB_DIR=$( echo $job | sed  's/-/_/g' )
OUT_DIR="$(pwd)/out/templates/$ENV/job_$JOB_DIR"
if [[ $output_redirect != "console" ]]; then
  rm -rf "$OUT_DIR"
  mkdir  -p "$OUT_DIR"
else
  OUT_DIR=""
fi

# Find image version and digest
bash $SCRIPTS_FOLDER/image-version-reader.sh -e $environment -j $job

TEMPLATE_CMD="helm template "
if [[ $enable_debug == true ]]; then
    TEMPLATE_CMD=$TEMPLATE_CMD"--debug "
fi

OUTPUT_FILE="\"$OUT_DIR/$job.out.yaml\""
OUTPUT_TO="> $OUTPUT_FILE"
if [[ $output_redirect == "console" ]]; then
  OUTPUT_TO=""
fi

TEMPLATE_CMD=$TEMPLATE_CMD" $job interop-eks-cronjob-chart/interop-eks-cronjob-chart -f \"$(pwd)/commons/$ENV/values-cronjob.compiled.yaml\" -f \"$(pwd)/jobs/$job/$ENV/values.yaml\" $OUTPUT_TO"

eval $TEMPLATE_CMD
if [[ $verbose == true ]]; then
  echo "Successfully created Helm Template for cronjob $job at $OUTPUT_FILE"
fi

if [[ $output_redirect != "console" && $post_clean == true ]]; then
  rm -rf $OUT_DIR
fi
