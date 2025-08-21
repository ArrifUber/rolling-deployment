#!/bin/bash

set -e

IMAGE="${DOCKER_USERNAME}/${DOCKER_REPO}:${TAG}"
echo "set image var: $IMAGE"


echo "Update docker-compose.yml with new image"
sudo sed -i "/app_rolling:/,/image:/ s|image: .*|image: ${IMAGE}|" docker-compose.yml


echo "Get number of running container"
running_container=$(docker ps -q --filter "name=app_rolling" | wc -l)

echo "Total running container is $running_container"

echo "Running rolling deployment"
for ((i = 0 ; i < $running_container ; i++ )); do
    echo "=== Rolling step $((i+1))/$running_container ===="

    container_replace=$(sudo docker ps --filter "name=app_rolling" --format {{.ID}} | tail -n 1)
    echo "Container to replace: $container_replace"

    echo "scale up 1 replica..."
    sudo docker compose up -d --scale app_rolling=$((running_container+1)) --no-recreate

    echo "Waiting for new container healthy..."
    new_container=$(sudo docker ps --filter "name=app_rolling" --format {{.ID}} | head -n 1)
    retries=5
    until sudo docker exec $new_container curl -fs http://localhost:5000/health || [ $retries -eq 0 ]; do
        echo "Wait new container $new_container healty..."
        sleep 3
        retries=$((retries-1))
    done

    if [ $retries -eq 0 ]; then
        echo "❌ New container failed health check. Rollback!"
        sudo docker stop $new_container
        sudo docker rm $new_container
        exit 1
    fi
    
    echo "✅ New Container healty. removing the old one..."
    sudo docker stop $container_replace
    sudo docker rm $container_replace
done

# echo "Run docker compose"
# sudo docker compose up -d --no-recreate

echo "Delete unused image..."
sudo docker image prune -a -f

echo "🎉 Running Complete"
