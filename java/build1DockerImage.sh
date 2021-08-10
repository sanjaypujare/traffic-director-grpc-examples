#!/bin/bash -x

IMAGENAME=psms-wallet-example
TAG=1.00
PROJECTID=meshca-gke-test

echo Building ${IMAGENAME}:${TAG}

docker build --build-arg builddate="$(date)" --no-cache -t zatar/${IMAGENAME}:${TAG} -f Dockerfile-wallet.common .

docker tag zatar/${IMAGENAME}:${TAG} gcr.io/${PROJECTID}/${IMAGENAME}:${TAG}

docker push gcr.io/${PROJECTID}/${IMAGENAME}:${TAG}
