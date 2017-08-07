#!/bin/bash

#set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

REPOSITORY=tmcsantos/java

die() {
    echo -e "${RED}$1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}$1${NC}"
}

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
    versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
    TAG=${version}-alpine
    dockerImage=$REPOSITORY:$TAG

    #docker build --rm --squash -t $dockerImage .
    #docker rmi $(docker images -a --filter=dangling=true -q) 2>/dev/null
    echo -n "building $dockerImage"
    docker build --rm --pull -t $dockerImage $version 1> /dev/null && \
    info " [done] " || die " [fail] "

    # test
    echo -n "testing $dockerImage"
    docker run --rm $dockerImage java -version 2> /dev/null && \
    info " [OK] " || die " [FAILED]"
done 