import os
import sys
import config as tc

### order of run ###

#### orderer
##### namespace(org)
###### single orderer

#### peer
##### namespace(org)
###### ca
####### single peer

def runOrderers(path):
	orgs = sorted(os.listdir(path))
	for org in orgs:
		orgPath = os.path.join(path, org)
		namespaceYaml = os.path.join(orgPath, org + "-namespace.yaml" ) #orgYaml namespace.yaml
		checkAndRun(namespaceYaml)

		for orderer in os.listdir(orgPath + "/orderers"):
			ordererPath = os.path.join(orgPath + "/orderers", orderer)
			ordererYaml = os.path.join(ordererPath, orderer + ".yaml")
			checkAndRun(ordererYaml)

def runPeer(orgPath, org):
	namespaceYaml = os.path.join(orgPath, org + "-namespace.yaml" ) # namespace.yaml
	checkAndRun(namespaceYaml)
	
	caYaml = os.path.join(orgPath, org + "-ca.yaml" ) # namespace.yaml
	checkAndRun(caYaml)   
	
	cliYaml = os.path.join(orgPath, org + "-cli.yaml" ) # namespace.yaml
	checkAndRun(cliYaml)    

	for peer in os.listdir(orgPath + "/peers"):
		peerPath = os.path.join(orgPath + "/peers", peer)
		peerYaml = os.path.join(peerPath, peer + ".yaml")
		checkAndRun(peerYaml)

def runPeers(path):
	orgs = sorted(os.listdir(path))
	for org in orgs:
		orgPath = os.path.join(path, org)
		runPeer(orgPath, org)

def runKafkas(path):
	namespaceYaml = os.path.join(path, "kafka-namespace.yaml")
	checkAndRun(namespaceYaml)

	for i in range(0, 3):
		zkYaml = os.path.join(path, "zookeeper" + str(i) + "-zookeeper.yaml")
		checkAndRun(zkYaml)
		# sleep(3)

	for i in range(0, 4):
		kafkaYaml = os.path.join(path, "kafka" + str(i) + "-kafka.yaml")
		checkAndRun(kafkaYaml)
		# sleep(5)

def checkAndRun(f):
	method = sys.argv[1] if len(sys.argv) > 1 else "create"
	if method == "up":
		method = "create"
	

	if os.path.isfile(f):
		os.system("kubectl " + method + " -f " + f + (" --save-config" if method == "create" else ""))

	else:
		print("file %s no exited"%(f))



if __name__ == "__main__":

	# if we run for 1 organization, in adding mode
	# using convert indentation to tab to avoid indent error
	if len(sys.argv) > 2 and sys.argv[2]:
		namespace = sys.argv[2]
		orgPath = os.path.join(tc.PEER, namespace)
		runPeer(orgPath, namespace)

	else:

		if len(os.listdir(tc.KAFKA)) > 1:
			runKafkas(tc.KAFKA)

		runOrderers(tc.ORDERER)
		runPeers(tc.PEER)
	

