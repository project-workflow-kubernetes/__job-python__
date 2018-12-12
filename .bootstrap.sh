#!/usr/bin/env bash

set -eo pipefail


while getopts ":j:" opt; do
  case $opt in
    j) JOB_NAME="$OPTARG";;
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
        sed -i.bak "s/__job-python__/${JOB_NAME}/" $f
        rm -- "${f}.bak"
    done;

}


function undo-rename-inside() {
    FILES="Dockerfile Makefile setup.py"

    for f in $FILES
    do
        sed -i.bak "s/${JOB_NAME}/__job-python__/" $f
        rm -- "${f}.bak"
    done;
}


function rename-folders () {
    FOLDERS="src/__job-python__/"

    for f in $FOLDERS
    do
        NEWFOLDER=${f//"__job-python__"/${JOB_NAME}}
        mv $f ${NEWFOLDER}
    done;

}

function undo-rename-folders() {
    FOLDERS="src/__job-python__/"

    for f in $FOLDERS
    do
        OLDFOLDER=${f//"__job-python__"/${JOB_NAME}}
        NEWFOLDER=${f//${JOB_NAME}/"__job-python__"}
        mv ${OLDFOLDER} ${NEWFOLDER}
    done;
}


function generate-secrets () {

    travis login --pro --auto

    if [ -z "$DOCKER_USERNAME" ]
    then
        echo "Please, enter your dockerhub login"
        echo
        read DOCKER_USERNAME
    fi

    travis encrypt --com DOCKER_USERNAME=$DOCKER_USERNAME --add

    if [ -z "$DOCKER_PASSWORD" ]
    then
        echo "Please, enter you dockerhub password - no one want to steal it"
        echo
        read DOCKER_PASSWORD
    fi

    travis encrypt --com DOCKER_PASSWORD=$DOCKER_PASSWORD --add

}

function remove-secrets () {

    sed -i.bak "/env:/d" .travis.yml && sed -i.bak "/global/d" .travis.yml && sed -i.bak "/- secure/d" .travis.yml
    rm -- ".travis.yml.bak" || true

}


function up () {

    (check-inputs)
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
