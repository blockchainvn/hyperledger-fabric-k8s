from string import Template
# from pathlib import Path
import string
import config as tc
import os
import sys
import argparse
import yaml


BASEDIR = os.path.dirname(__file__)
ORDERER = os.path.join(BASEDIR, "../crypto-config/ordererOrganizations")
PEER = os.path.join(BASEDIR, "../crypto-config/peerOrganizations")
KAFKA = os.path.join(BASEDIR, "../crypto-config/kafka")

#generateNamespacePod generate the yaml file to create the namespace for k8s, and return a set of paths which indicate the location of org files  

def generateKafka(DIR, override):
    tc.configKafkaNamespace(DIR, override)
    tc.configZookeepers(DIR, override)
    tc.configKafkas(DIR, override)

def generateNamespacePod(DIR, override):
	orderer0 = sorted(os.listdir(ORDERER))[0]
	orgs = []
	# remain ordered list
	for index, org in enumerate(sorted(os.listdir(DIR))):
		orgDIR = os.path.join(DIR, org)
		## generate namespace first.
		tc.configORGS(org, orgDIR, orderer0, override, index)
		orgs.append(orgDIR)
		#orgs.append(orgDIR + "/" + DIR.lower())
	
	#print(orgs)	
	return orgs


def generateDeploymentPod(orgs, override):
	for orgindex, org in enumerate(orgs):

		if org.find("peer") != -1: #whether it create orderer pod or peer pod 
			suffix = "/peers"
		else:
			suffix = "/orderers"

		members = os.listdir(org + suffix)
		for member in members:
			#print(member)
			memberDIR = os.path.join(org + suffix, member)
			#print(memberDIR)
			#print(os.listdir(memberDIR))
			tc.generateYaml(member,memberDIR, suffix, override, orgindex)


#TODO kafa nodes and zookeeper nodes don't have dir to store their certificate, must use anotherway to create pod yaml.

def allInOne(override, file):
	peerOrgs = generateNamespacePod(PEER, override)
	generateDeploymentPod(peerOrgs, override)

	# check more than 1 order then run this
	stream = open(file, "r")
	YAML = yaml.load(stream)
	if YAML["OrdererOrgs"][0]["Template"]["Count"] > 1:
		generateKafka(KAFKA, override)

	ordererOrgs = generateNamespacePod(ORDERER, override)
	generateDeploymentPod(ordererOrgs, override)

def processArguments():
	parser = argparse.ArgumentParser(description='Generate network artifacts.')	
	parser.add_argument('--nfs-server', dest='NSF_SERVER', type=str,
	                    help='NSF_SERVER IP (default: ' + tc.NSF_SERVER + ')')
	parser.add_argument('--version', dest='VERSION', type=str,
	                    help='Fabric version (default: ' + tc.VERSION + ')')
	parser.add_argument('--tls-enabled', dest='TLS_ENABLED', type=str,
	                    help='Enable tls mode (default: ' + tc.TLS_ENABLED + ')')
	parser.add_argument('--env', dest='ENV', type=str,
	                    help='Fabric environment (default: ' + tc.ENV + ')')
	parser.add_argument('--file', dest='FILE', type=str,
	                    help='Config file')
	parser.add_argument('--share', dest='SHARE_FOLDER', type=str,
	                    help='Share Folder (default: ' + tc.SHARE_FOLDER + ')')
	
	parser.add_argument("-o", "--override", dest='OVERRIDE', type=str, default="false", help="Override existing k8s yaml files")	

	# config_file = sys.argv[1] if len(sys.argv) > 1 else "cluster-config.yaml"

	# stream = open(config_file, "r")
	# YAML = yaml.load(stream)

	args = parser.parse_args()	

	tc.NSF_SERVER = args.NSF_SERVER or tc.NSF_SERVER
	tc.VERSION = args.VERSION or tc.VERSION
	tc.TLS_ENABLED = args.TLS_ENABLED or tc.TLS_ENABLED
	tc.ENV = args.ENV or tc.ENV
	tc.SHARE_FOLDER = args.SHARE_FOLDER or tc.SHARE_FOLDER

	print('Setup network NSF_SERVER:{0}, VERSION:{1}, TLS_ENABLED:{2}, OVERRIDE:{3}'
		.format(tc.NSF_SERVER, tc.VERSION, tc.TLS_ENABLED, args.OVERRIDE))	
	
	return args

if __name__ == "__main__" :	
	args = processArguments()
	allInOne(True if args.OVERRIDE == "true" else False, args.FILE)	
	
	
	
