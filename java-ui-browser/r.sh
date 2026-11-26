#!/bin/bash
export IMAGE=java-ui-browser
echo ===== Build image =====
docker build -t $IMAGE .
echo ===== Run container =====
docker run --rm $IMAGE
