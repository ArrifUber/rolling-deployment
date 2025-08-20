#!/bin/bash

set -e
echo "Get number of running container"
running_container=$(docker ps -q --filter "name=app_rolling" | wc -l)
echo "Total running container is $running_container"
echo "Running rolling deployment"

for ((i = 0 ; i < $running_container ; i++ )); do
    echo "hai $i"
done
# for ((i = 0 ; i < $running_container ; i++ )); do
#     echo "running $i ...."
#     container_delete=$(docker ps --filter "name=app_rolling" --format {{.ID}} | tail -n 1)
#     echo "------> $container_delete"
#     docker compose up -d --scale app_rolling=4 --no-recreate
#     sleep 10
#     echo "Delete container $container_delete"
#     docker stop $container_delete
#     docker rm $container_delete
#     sleep 5
#     echo "running $i done"
# done