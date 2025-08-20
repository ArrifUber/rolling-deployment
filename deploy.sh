#!/bin/bash

set -e

IMAGE="${DOCKER_USERNAME}/${DOCKER_REPO}:${TAG}"
echo "set image var: $IMAGE"


echo "Set new image to docker compose file"
sudo sed -i "/app_rolling:/,/image:/ s|image: .*|image: ${IMAGE}|" docker-compose.yml

echo "Run docker compose"
sudo docker compose up -d --no-recreate

echo "Get number of running container"
running_container=$(docker ps -q --filter "name=app_rolling" | wc -l)

echo "Total running container is $running_container"

echo "Running rolling deployment"
for ((i = 0 ; i < $running_container ; i++ )); do
    echo "running step $i ...."
    echo "set container id to delete: $container_delete"
    container_delete=$(sudo docker ps --filter "name=app_rolling" --format {{.ID}} | tail -n 1)

    echo "scale up replica"
    sudo docker compose up -d --scale app_rolling=4 --no-recreate

    echo "wait 5s..."
    sleep 5
    echo "Delete container with id: $container_delete"
    sudo docker stop $container_delete
    sudo docker rm $container_delete
    echo "Wait 5s.."
    sleep 5
    echo "running step $i done"
done

echo "Delete unused image..."
sudo docker image prune -a -f

echo "Running Complete ✅"
