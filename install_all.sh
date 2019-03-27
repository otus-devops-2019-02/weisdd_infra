#!/bin/bash
# Installing Ruby
apt update
apt install -y ruby-full ruby-bundler build-essential
# Installing Mongodb
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod
# Since instances run startup scripts as root, and we don't want our web-server to have such privileges,
# we need to use either runuser or su to workaround that.
# For reference:
# https://www.cyberciti.biz/open-source/command-line-hacks/linux-run-command-as-different-user/
runuser -l appuser -c 'git clone -b monolith https://github.com/express42/reddit.git'
runuser -l appuser -c 'cd reddit && bundle install'
runuser -l appuser -c 'cd reddit && puma -d'
