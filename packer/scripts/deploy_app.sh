#!/bin/bash
set -e

cd /home/appuser
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
