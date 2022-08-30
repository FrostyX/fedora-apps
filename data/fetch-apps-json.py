"""
Download apps.yaml from
https://github.com/fedora-infra/apps.fp.o
and convert it to a format, that is expected by Elm
"""

import json
import yaml
import requests


url = "https://raw.githubusercontent.com/fedora-infra/apps.fp.o/develop/data/apps.yaml"
response = requests.get(url)
assert response.status_code == 200

# Dump YAML file
with open("apps.yaml", "w") as fd:
    fd.write(response.text)

# Read YAML file
with open("apps.yaml", "r") as fd:
    data = yaml.load(fd, Loader=yaml.SafeLoader)

# The Elm parser expect even the root app node to be inside of a list
data = [data]

# Write YAML object to JSON format
with open("apps.json", "w") as fd:
    json.dump(data, fd, sort_keys=False)
