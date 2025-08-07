#!/bin/bash

docker service create \
  --name cronjob-$(date +%s) \
  --restart-condition none \
  --mount type=bind,source=/d/cronlogs,target=/output \
  nikampradyumna/cronjob-example:latest

