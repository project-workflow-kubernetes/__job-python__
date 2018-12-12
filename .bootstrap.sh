#!/usr/bin/env bash

set -eo pipefail

DEFAULT_JOB='job-python-skeleton'
DEFAULT_REPO='liabifano'


while getopts ":j:u:p:" opt; do
  case $opt in
      j) JOB_NAME="$OPTARG";;
      u) DOCKER_USERNAME="$OPTARG";;
      p) DOCKER_PASSWORD="$OPTARG";;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done



function check-inputs () {
    if [[ -z "$JOB_NAME" ]]; then
        echo "You must specify the job name with the flag -j"
        exit 1
    fi
}


function rename-inside () {

    FILES="Dockerfile Makefile setup.py"

    for f in $FILES
    do
        sed -i.bak "s/${DEFAULT_JOB}/${JOB_NAME}/" $f
        rm -- "${f}.bak"
    done;

    sed -i.bak "s/${DEFAULT_REPO}/${DOCKER_USERNAME}/" Makefile
    rm -- "${f}.bak"

}


function undo-rename-inside() {
    FILES="Dockerfile Makefile setup.py"

    for f in $FILES
    do
        sed -i.bak "s/${JOB_NAME}/${DEFAULT_JOB}/" $f
        rm -- "${f}.bak"
    done;

    sed -i.bak "s/${DOCKER_USERNAME}/${DEFAULT_REPO}/" $f
    rm -- "${f}.bak"
}


function rename-folders () {
    FOLDERS="src/${DEFAULT_JOB}/"

    for f in $FOLDERS
    do
        NEWFOLDER=${f//${DEFAULT_JOB}/${JOB_NAME}}
        mv $f ${NEWFOLDER}
    done;

}

function undo-rename-folders() {
    FOLDERS="src/${DEFAULT_JOB}/"

    for f in $FOLDERS
    do
        OLDFOLDER=${f//${DEFAULT_JOB}/${JOB_NAME}}
        NEWFOLDER=${f//${JOB_NAME}/"${DEFAULT_JOB}"}
        mv ${OLDFOLDER} ${NEWFOLDER}
    done;
}


function generate-secrets () {

    travis login --pro --auto
    travis encrypt --com DOCKER_USERNAME=$DOCKER_USERNAME --add
    travis encrypt --com DOCKER_PASSWORD=$DOCKER_PASSWORD --add

}

function remove-secrets () {

    sed -i.bak "/env:/d" .travis.yml && sed -i.bak "/global/d" .travis.yml && sed -i.bak "/- secure/d" .travis.yml
    rm -- ".travis.yml.bak" || true

}


function up () {

    (check-inputs)
    (remove-secrets)
    (rename-inside)
    (rename-folders)
    (generate-secrets)

}


function down () {

    (check-inputs)
    (undo-rename-inside)
    (undo-rename-folders)
    (remove-secrets)

}


case "${@: -1}" in
  (up)
    up
    exit 0
    ;;
  (down)
      down
    exit 0
    ;;
  (generate-secrets)
      generate-secrets
    exit 0
    ;;
  (remove-secrets)
      remove-secrets
    exit 0
    ;;
  (*)
    echo "Usage: $0 { up | down | remove-secrets | generate-secrets }"
    exit 2
    ;;
esac
