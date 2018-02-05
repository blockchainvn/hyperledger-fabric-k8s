import yaml
import sys

config_file = sys.argv[1] if len(sys.argv) > 1 else "cluster-config.yaml"

stream = open(config_file, "r")
YAML = yaml.load(stream)
tenant = YAML["Tenant"]
for k, v in YAML.items() : 
	#change the yaml, add suffix tenant to every org 
	if k == "PeerOrgs" or k == "OrdererOrgs":
		for org in v :
			org["Domain"] = org["Domain"] + "-" + tenant
	#	#generate Kafka pod yaml
	#elif k == "Kafka":
	#	pass
	#	#generate zookeeper pod yaml
	#elif k == "zookeeper":
	#	pass
	# move these to generate.py

cryptoConfig = open("./crypto-config.yaml", 'w')
yaml.dump(YAML, cryptoConfig)

