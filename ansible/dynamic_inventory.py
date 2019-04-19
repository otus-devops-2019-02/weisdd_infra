#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from collections import defaultdict
import os.path
import configparser
from pprint import pprint
from googleapiclient import discovery
import json


def list_instances(compute, project, zone):
    result = compute.instances().list(project=project, zone=zone).execute()
    return result['items'] if 'items' in result else None


def prepare_ansible_config(instances):
    pass

def main():
    ansible_default_group = 'ungrouped'
    ansible_group_label = 'ansible_group'
    default_project = 'project-12345'  # if undefined in gcloud settings
    default_zone = 'europe-west1-b'  # if undefined in gcloud settings
    gcloud_default_config = os.path.expanduser('~') + '/.config/gcloud/configurations/config_default'

    config = configparser.ConfigParser()
    config.read(gcloud_default_config)
    project = config['core'].get('project', default_project)
    zone = config['compute'].get('zone', default_zone)
    # print(project, zone)
    compute = discovery.build('compute', 'v1')
    instances = list_instances(compute, project, zone)
    print(instances)
    tree = lambda: defaultdict(tree)
    ansible_data = tree()
    for instance in instances:
        name = instance['name']
        print(name)
        private_ip = instance['networkInterfaces'][0]['networkIP']
        if 'accessConfigs' in instance['networkInterfaces'][0] and 'natIP' in \
                instance['networkInterfaces'][0]['accessConfigs'][0]:
            public_ip = instance['networkInterfaces'][0]['accessConfigs'][0]['natIP']
        else:
            public_ip = None
        if 'labels' in instance and ansible_group_label in instance['labels']:
            ansible_group = instance['labels'][ansible_group_label]
        else:
            ansible_group = ansible_default_group
        # https://stackoverflow.com/questions/15819428/how-to-initialize-nested-dictionaries-in-python

        ansible_data[ansible_group]['hosts'][name]['ansible_host'] = public_ip if public_ip else private_ip

        ansible_data['_meta']['hostvars'] = {}
    print(json.dumps(ansible_data, sort_keys=True, indent=2))
    # with open('dynamic_inventory_cache', 'w', encoding='utf-8') as f:
    #     json.dump(instances, f)

if __name__ == '__main__':
    main()
