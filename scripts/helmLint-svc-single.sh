#!/bin/bash
set -euo pipefail

. $(dirname "$0")/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to detect values.yaml for linting
        [ -d | --debug ] Enable Helm template debug
        [ -m | --microservice ] Microservice defined in microservices folder
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print linting output on terminal
        [ -c | --clean ] Clean files and directories after script successfull execution
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
microservice=""
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
if [[ -z $microservice || $microservice == "" ]]; then
  echo "Microservice cannot be null"
  help
fi
if [[ $skip_dep == false ]]; then
  bash $(dirname "$0")/helmDep.sh --untar
fi

VALID_CONFIG=$(isMicroserviceEnvConfigValid $microservice $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "Environment configuration '$environment' not found for microservice '$microservice'"
  help
fi

ENV=$environment
OUT_DIR="./out/lint/$ENV/svc_$microservice"
OUT_DIR=$( echo $OUT_DIR | sed  's/-/_/g' )
if [[ $output_redirect != "console" ]]; then
  rm -rf $OUT_DIR
  mkdir  -p $OUT_DIR
else
  OUT_DIR=""
fi

# Find image version and digest
. $(dirname "$0")/image-version-reader.sh -e $environment -m $microservice

LINT_CMD="helm lint "
if [[ $enable_debug == true ]]; then
    LINT_CMD=$LINT_CMD"--debug "
fi

OUTPUT_TO="> $OUT_DIR/$microservice.out.yaml"
if [[ $output_redirect == "console" ]]; then
  OUTPUT_TO=""
fi

LINT_CMD=$LINT_CMD" charts/interop-eks-microservice-chart -f charts/interop-eks-microservice-chart/values.yaml -f commons/$ENV/values-microservice.compiled.yaml -f microservices/$microservice/$ENV/values.yaml $OUTPUT_TO"

echo "$(eval $LINT_CMD)"$'\n\n'

if [[ $output_redirect != "console" && $post_clean == true ]]; then
  rm -rf $OUT_DIR
fi
