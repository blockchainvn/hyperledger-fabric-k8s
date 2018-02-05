import yaml
import re

name = "ips1-v1"
pattern = re.compile('(\d+)$')
result = re.search(pattern, name.split("-")[0])
print result.group(0) if result else 1