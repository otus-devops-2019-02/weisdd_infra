#!/usr/bin/env bash
set -e

mv /home/appuser/puma.service /etc/systemd/system/
cd /etc/systemd/system
chown root:root puma.service
systemctl enable puma.service
sudo systemctl start puma.service
