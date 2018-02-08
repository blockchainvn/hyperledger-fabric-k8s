import yaml
import re

import assignTenant as at

print (at.YAML["OrdererOrgs"][0]["Template"]["Count"])

# name = "ips1-v1"
# pattern = re.compile('(\d+)$')
# result = re.search(pattern, name.split("-")[0])
# print result.group(0) if result else 1
# ENV = "DEV"
# print "start --peer-chaincodedev=true" if ENV == "DEV" else "start"