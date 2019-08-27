#!/bin/bash

usage() {
    echo "Usage: $0 -w {WELLVIZ_3D_DOCKER_IMAGE_TAG} -d {DOCKER_IMAGE_TAG}" 1>&2
    exit 1
}

wellViz3dTag=false
tagFlag=false

while getopts ":w:d:" opt; do
    case ${opt} in
    w)
        wellViz3dTag=true
        WELLVIZ3D_TAG=$OPTARG
        ;;
    d)
        tagFlag=true
        TAG=$OPTARG
        ;;
    h | [?])
        usage
        exit
        ;;
    esac
done
shift $((OPTIND - 1))

if ! $wellViz3dTag; then
    echo "WellViz3D Docker Image tag must be provided." >&2
    usage
    exit 1
fi

if ! $tagFlag; then
    TAG='latest'
fi

echo 'Building image'

docker build . \
    --tag=docker-registry.edrilling.no/wellviz3d:vnc-$TAG \
    --build-arg WELLVIZ3D_TAG="${WELLVIZ3D_TAG}"

echo Pushing image to docker-registry.edrilling.no/wellviz3d:vnc-$TAG

docker push docker-registry.edrilling.no/wellviz3d:vnc-$TAG

