from string import Template
# from pathlib import Path
import string
import config as tc
import os
import sys
import argparse


BASEDIR = os.path.dirname(__file__)
ORDERER = os.path.join(BASEDIR, "../crypto-config/ordererOrganizations")
PEER = os.path.join(BASEDIR, "../crypto-config/peerOrganizations")

#generateNamespacePod generate the yaml file to create the namespace for k8s, and return a set of paths which indicate the location of org files  

def generateNamespacePod(DIR):
	orderer0 = sorted(os.listdir(ORDERER))[0]
	orgs = []
	for org in os.listdir(DIR):
		orgDIR = os.path.join(DIR, org)
		## generate namespace first.
		tc.configORGS(org, orgDIR, orderer0)
		orgs.append(orgDIR)
		#orgs.append(orgDIR + "/" + DIR.lower())
	
	#print(orgs)	
	return orgs


def generateDeploymentPod(orgs):
	for org in orgs:

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
			tc.generateYaml(member,memberDIR, suffix)


#TODO kafa nodes and zookeeper nodes don't have dir to store their certificate, must use anotherway to create pod yaml.

def allInOne():
	peerOrgs = generateNamespacePod(PEER)
	generateDeploymentPod(peerOrgs)

	ordererOrgs = generateNamespacePod(ORDERER)
	generateDeploymentPod(ordererOrgs)

def processArguments():
	parser = argparse.ArgumentParser(description='Generate network artifacts.')	
	parser.add_argument('--nfs-server', dest='NSF_SERVER', type=str,
	                    help='NSF_SERVER IP (default: ' + tc.NSF_SERVER + ')')
	parser.add_argument('--version', dest='VERSION', type=str,
	                    help='Fabric version (default: ' + tc.VERSION + ')')
	parser.add_argument('--tls-enabled', dest='TLS_ENABLED', type=str,
	                    help='Enable tls mode (default: ' + tc.TLS_ENABLED + ')')
	args = parser.parse_args()	

	tc.NSF_SERVER = args.NSF_SERVER or tc.NSF_SERVER
	tc.VERSION = args.VERSION or tc.VERSION
	tc.TLS_ENABLED = args.TLS_ENABLED or tc.TLS_ENABLED

	print('Setup network NSF_SERVER:{0}, VERSION:{1}, and TLS_ENABLED:{2}.'
		.format(tc.NSF_SERVER, tc.VERSION, tc.TLS_ENABLED))	

if __name__ == "__main__" :	
	processArguments()
	allInOne()	
	
	
	
