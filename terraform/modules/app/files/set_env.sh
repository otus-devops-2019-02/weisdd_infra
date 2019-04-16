#!/bin/bash
set -e

DATABASE_URL="${1:-127.0.0.1:27017}"
echo $DATABASE_URL
# Supplies reddit app with a link to database, it's useful when a db server is
# installed on another host
bash -c "echo 'DATABASE_URL=${DATABASE_URL}' > ~/reddit_app_service.conf"
