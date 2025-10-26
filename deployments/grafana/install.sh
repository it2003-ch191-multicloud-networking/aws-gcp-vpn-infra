#!/bin/bash

mkdir -p /opt/grafana
cat <<EOF >/opt/grafana/docker-compose.yml
services:
  grafana:
    image: grafana/grafana
    container_name: grafana
    restart: unless-stopped
    ports:
     - '3000:3000'
    volumes:
      - grafana-storage:/var/lib/grafana
volumes:
  grafana-storage: {}
EOF

docker-compose -f /opt/grafana/docker-compose.yml up -d