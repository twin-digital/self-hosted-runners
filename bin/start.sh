#!/usr/bin/env bash

sudo -u gha-runners /bin/bash -c 'cd ~/self-hosted-runners/common-lift/large && docker-compose down && docker-compose up --build -d'
