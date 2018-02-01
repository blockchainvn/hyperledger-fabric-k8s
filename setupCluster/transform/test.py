import yaml

stream = open("./cluster-config.yaml", "r")
YAML = yaml.load(stream)
tenant = YAML["Tenant"]

domain = "domain"
domain = domain + ("-" + tenant if tenant else "")

print (domain)