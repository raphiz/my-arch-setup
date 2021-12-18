#!/usr/bin/python3
import urllib.request
import re
from ruamel.yaml import YAML
import os


def fetch_latest_pkg_hash(pkg_name):
    print(f"Fetching hash for {pkg_name}")
    url = f'https://aur.archlinux.org/cgit/aur.git/commit/PKGBUILD?h={pkg_name}'
    contents = urllib.request.urlopen(url).read().decode('utf8')
    commit_regex = re.compile('<tr><th>commit<\/th><td [^>]*><a [^>]*>([a-z0-9]+)<\/a>')
    hash = commit_regex.findall(contents)[0]
    return hash

def update_group_vars():
    update_vars('/config/group_vars/all.yml')

def update_host_vars():
    try:
        host_vars_dir = '/config/hosts/inventory/host_vars'
        for host_vars in os.listdir(host_vars_dir):
            update_vars(os.path.join(host_vars_dir, host_vars))
    except FileNotFoundError:
        print("No host_vars found")

def update_vars(path):
    if open(path).read(15) == "$ANSIBLE_VAULT;":
        print(f"WARNING: {path} is encrypted and is therefore skipped")
        return
    yaml = YAML(typ='rt')
    vars = yaml.load(open(path).read())
    for pkg in vars.get('desktop_apps_aur', {}).get('base', []):
        pkg['hash'] = fetch_latest_pkg_hash(pkg['name'])
    for pkg in vars.get('aur_fonts', []):
        pkg['hash'] = fetch_latest_pkg_hash(pkg['name'])
    for pkg in vars.get('apps_aur', []):
        pkg['hash'] = fetch_latest_pkg_hash(pkg['name'])
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.dump(vars, open(path, 'w'))


def update_role_tasks():
    role_dir = "/config/roles"
    for role in os.listdir(role_dir):
        role_path = os.path.join(role_dir, role)
        tasks_path = os.path.join(role_path, 'tasks')
        if os.path.isdir(role_path) and os.path.exists(tasks_path):
            for task_file in os.listdir(tasks_path):
                update_task(os.path.join(tasks_path, task_file))

def update_task(path):
    print(f"Checking for AUR updates in {path}")
    yaml = YAML(typ='rt')
    yaml.preserve_quotes = True
    yaml.default_flow_style = False
    yaml.width = None
    tasks = yaml.load(open(path).read())
    for task in tasks:
        if 'aur' in task and not task['aur']['name'].startswith('{{'):
            task['aur']['hash'] = fetch_latest_pkg_hash(task['aur']['name'])
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.dump(tasks, open(path, 'w'), transform=skip_root_list_indent)

def skip_root_list_indent(thing):
    thing = re.sub(re.compile(r"^  ", flags=re.MULTILINE), "", thing)
    return thing

if __name__ == '__main__':
    update_group_vars()
    update_host_vars()
    update_role_tasks()
    