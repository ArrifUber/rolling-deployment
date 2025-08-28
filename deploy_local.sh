#!/bin/bash

set -e
echo "Get number of running container"
running_container=$(docker ps -q --filter "name=app_rolling" | wc -l)
echo "Total running container is $running_container"
echo "Running rolling deployment"

for ((i = 0 ; i < $running_container ; i++ )); do
    echo "=== Rolling step $((i+1))/$running_container ===="

    container_replace=$(docker ps --filter "name=app_rolling" --format {{.ID}} | tail -n 1)
    echo "Container to replace: $container_replace"

    echo "scale up 1 replica..."
    docker compose up -d --scale app_rolling=$((running_container+1)) --no-recreate

    echo "Waiting for new container healthy..."
    new_container=$(docker ps --filter "name=app_rolling" --format {{.ID}} | head -n 1)
    retries=10
    until docker exec $new_container curl -fs http://localhost:5000/health || [ $retries -eq 0 ]; do
        echo "Wait new container $new_container healty..."
        sleep 3
        retries=$((retries-1))
    done

    if [ $retries -eq 0 ]; then
        echo "❌ New container failed health check at step $((i+1))"
        echo "Running Rollback..."
        echo "Update docker-compose.yml with previously image"

        echo "Remove the new container..."
        docker rm $(docker stop $(docker ps --filter "ancestor=$IMAGE" --format "{{.ID}}"))

        docker compose up -d --scale app_rolling=$running_container --no-recreate

        echo "✅ Rollback Complete"
        exit 1
    fi
    
    echo "✅ New Container healty. removing the old one..."
    docker stop -t 10 $container_replace
    docker rm $container_replace
done

echo "Yey selesai"