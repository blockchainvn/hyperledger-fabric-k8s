from string import Template
#from pathlib import Path
import re
import string
import os

TestDir = './dest/'
PORT_START_FROM = 30500
ZOOKEEPER_PORT_START_FROM = 32750
KAFKA_PORT_START_FROM = 32730
GAP = 100  #interval for worker's port
NSF_SERVER = '192.168.99.1'
VERSION = '1.0.2'
TLS_ENABLED = 'false'
ENV = 'DEV'
SHARE_FOLDER = '/opt/share'

BASEDIR = os.path.dirname(__file__)
ORDERER = os.path.join(BASEDIR, "../crypto-config/ordererOrganizations")
PEER = os.path.join(BASEDIR, "../crypto-config/peerOrganizations")
KAFKA = os.path.join(BASEDIR, "../crypto-config/kafka")

def render(src, dest, **kw):
	t = Template(open(src, 'r').read())	
	options = dict(version = VERSION, tlsEnabled = TLS_ENABLED, shareFolder = SHARE_FOLDER, **kw)    
	with open(dest, 'w') as f:
		f.write(t.substitute(**options))

	##### For testing ########################
	##testDest = dest.split("/")[-1]	##
	##with open(TestDir+testDest, 'w') as d:##
	##d.write(t.substitute(**kw))      	##
	##########################################

def condRender(src, dest, override, **kw):
  if not os.path.exists(dest):
      render(src, dest, **kw)
  elif os.path.exists(dest) and override:
      render(src, dest, **kw)

def getTemplate(templateName):
	baseDir = os.path.dirname(__file__)
	configTemplate = os.path.join(baseDir, "../templates/" + templateName)
	return configTemplate

def getAddressSegment(index):
	# pattern = re.compile('(\d+)$')
	# result = re.search(pattern, name.split("-")[0])
	# return (int(result.group(0)) -1 if result else 0) * GAP	
	return index * GAP

def configKafkaNamespace(path, override):
    namespaceTemplate = getTemplate("template_kafka_namespace.yaml")
    condRender(namespaceTemplate, path + "/" + "kafka-namespace.yaml", override)

# bydefault 3 kafka and 4 zookeeper as channel, and multiple orderer will be scale based on this
def configZookeepers(path, override):
    for i in range(0, 3):
        zkTemplate = getTemplate("template_zookeeper.yaml")
        zkPodName = "zookeeper" + str(i) + "-kafka"
        zookeeperID = "zookeeper" + str(i)
        seq = i + 1
        nodePort1 = ZOOKEEPER_PORT_START_FROM + (i * 3 + 1)
        nodePort2 = nodePort1 + 1
        nodePort3 = nodePort2 + 1
        zooServersTemplate = "server.1=zookeeper0.kafka:2888:3888 server.2=zookeeper1.kafka:2888:3888 server.3=zookeeper2.kafka:2888:3888"
        zooServers = zooServersTemplate.replace("zookeeper" + str(i) + ".kafka", "0.0.0.0")
        
        condRender(zkTemplate, path + "/" + zookeeperID + "-zookeeper.yaml", override,
           zkPodName=zkPodName, 
           zookeeperID=zookeeperID, 
           seq=seq, 
           zooServers=zooServers,
           nodePort1=nodePort1, 
           nodePort2=nodePort2, 
           nodePort3=nodePort3
				)


def configKafkas(path, override):
    for i in range(0, 4):
        kafkaTemplate = getTemplate("template_kafka.yaml")
        kafkaPodName = "kafka" + str(i) + "-kafka"
        kafkaID = "kafka" + str(i)
        seq = i
        nodePort1 = KAFKA_PORT_START_FROM + (i * 2 + 1)
        nodePort2 = nodePort1 + 1
        advertisedHostname = "kafka" + str(i) + ".kafka"

        condRender(kafkaTemplate, path + "/" + kafkaID + "-kafka.yaml", override,
           kafkaPodName=kafkaPodName, 
           kafkaID=kafkaID, 
           seq=seq,
           advertisedHostname=advertisedHostname, 
           nodePort1=nodePort1,
           nodePort2=nodePort2
        )



# create org/namespace 
# copy to SHARE_FOLDER => need to map to nfs
def configORGS(name, path, orderer0, override, index): # name means if of org, path describe where is the namespace yaml to be created. 	
	namespaceTemplate = getTemplate("template_namespace.yaml")
	hostPath = path.replace("transform/../", SHARE_FOLDER + "/")
  # addressSegment = (int(orgName.split("-")[0].split("org")[-1]) - 1) * GAP
  # addressSegment = 
  
  ##peer from like this peer 0##
  

	condRender(namespaceTemplate, path + "/" + name + "-namespace.yaml", override,
		org = name,
		pvName = name + "-pv",
		nsfServer = NSF_SERVER,
		path = hostPath
	)

	
	if path.find("peer") != -1 :
		####### pod config yaml for org cli
		cliTemplate = getTemplate("template_cli.yaml")
		
		mspPathTemplate = 'users/Admin@{}/msp'
		tlsPathTemplate =  'users/Admin@{}/tls'		


		condRender(cliTemplate, path + "/" + name + "-cli.yaml", override,
			name = "cli",
			namespace = name,
			mspPath = mspPathTemplate.format(name),
			tlsPath = tlsPathTemplate.format(name),
			pvName = name + "-pv",
			nsfServer = NSF_SERVER,
      artifactsName = name + "-artifacts-pv",
			peerAddress = "peer0." + name + ":7051",
			mspid = name.split('-')[0].capitalize()+"MSP",
			orderer0 = orderer0,
			path = hostPath
		)
		#######

		####### pod config yaml for org ca

		###Need to expose pod's port to worker ! ####
		##org format like this org1-f-1##
		# addressSegment = (int(name.split("-")[0].split("org")[-1]) - 1) * GAP			
		addressSegment = getAddressSegment(index)	
		# each oganization should have unique ip, so ip + port should be unique
		exposedPort = PORT_START_FROM + addressSegment

		caTemplate = getTemplate("template_ca.yaml")
		
		tlsCertTemplate = '/etc/hyperledger/fabric-ca-server-config/{}-cert.pem'
		tlsKeyTemplate = '/etc/hyperledger/fabric-ca-server-config/{}'
		caPathTemplate = 'ca/'
		cmdTemplate =  ' fabric-ca-server start --ca.certfile /etc/hyperledger/fabric-ca-server-config/{}-cert.pem --ca.keyfile /etc/hyperledger/fabric-ca-server-config/{} -b admin:adminpw -d '

		skFile = ""
		for f in os.listdir(path+"/ca"):  # find out sk!
			if f.endswith("_sk"):
				skFile = f
			
		condRender(caTemplate, path + "/" + name + "-ca.yaml", override,
			namespace = name,
			command = '"' + cmdTemplate.format("ca."+name, skFile) + '"',
			caPath = caPathTemplate,
			tlsKey = tlsKeyTemplate.format(skFile),	
			tlsCert = tlsCertTemplate.format("ca."+name),
			nodePort = exposedPort,
			pvName = name + "-pv",
			path = hostPath 
		)
		#######

def generateYaml(member, memberPath, flag, override, index):
	if flag == "/peers":
		configPEERS(member, memberPath, override, index)
	else:
		configORDERERS(member, memberPath, override, index) 
	

# create peer/pod
def configPEERS(name, path, override, index): # name means peerid.
	configTemplate = getTemplate("template_peer.yaml")
	hostPath = path.replace("transform/../", SHARE_FOLDER + "/")
	mspPathTemplate = 'peers/{}/msp'
	tlsPathTemplate =  'peers/{}/tls'
	#mspPathTemplate = './msp'
	#tlsPathTemplate = './tls'
	nameSplit = name.split(".")
	peerName = nameSplit[0]
	orgName = nameSplit[1]

	# addressSegment = (int(orgName.split("-")[0].split("org")[-1]) - 1) * GAP
	addressSegment = getAddressSegment(index)
	##peer from like this peer 0##
	peerOffset = int((peerName.split("peer")[-1])) * 4
	exposedPort1 = PORT_START_FROM + addressSegment + peerOffset + 1
	exposedPort2 = PORT_START_FROM + addressSegment + peerOffset + 2
	exposedPort3 = PORT_START_FROM + addressSegment + peerOffset + 3  
	
	condRender(configTemplate, path + "/" + name + ".yaml", override,
		namespace = orgName,
		podName = peerName + "-" + orgName,
		peerID  = peerName,
		org = orgName, 
		corePeerID = name,
    # peerAddress and peerCCAddress are for chaincode container to connect
		# peerAddress = name + ":7051",
    peerAddress = name + ":" + str(exposedPort1),
		# peerCCAddress = name + ":7052",
    peerCCAddress = name + ":" + str(exposedPort2),
		peerGossip = name  + ":7051",
		localMSPID = orgName.split('-')[0].capitalize()+"MSP",
		mspPath = mspPathTemplate.format(name),
		tlsPath = tlsPathTemplate.format(name),
		nodePort1 = exposedPort1,
		nodePort2 = exposedPort2,
		nodePort3 = exposedPort3,
    pvName = orgName + "-pv",
    path = hostPath,
    # version 1.0, 0.6 will not using address auto detect
    addressAutoDetect = "false" if re.match(r"^(?:1\.0|0\.6)\.*", VERSION) else "true",
    peerCmd = "start --peer-chaincodedev=true" if ENV == "DEV" else "start"
	)


# create orderer/pod
def configORDERERS(name, path, override, index): # name means ordererid
	configTemplate = getTemplate("template_orderer.yaml")
	hostPath = path.replace("transform/../", SHARE_FOLDER + "/")
	genesisPath = os.path.dirname(os.path.dirname(hostPath))
	mspPathTemplate = 'orderers/{}/msp'
	tlsPathTemplate = 'orderers/{}/tls'

	nameSplit = name.split(".")
	ordererName = nameSplit[0]
	orgName = nameSplit[1]
	
	ordererOffset = int(ordererName.split("orderer")[-1])
	addressSegment = getAddressSegment(index) 
	exposedPort = 32000 + addressSegment + ordererOffset

	condRender(configTemplate, path + "/" + name + ".yaml", override, 
		namespace = orgName,
		ordererID = ordererName,
		podName =  ordererName + "-" + orgName,
		localMSPID =  ordererName.capitalize() + "MSP",
		mspPath= mspPathTemplate.format(name),
		tlsPath= tlsPathTemplate.format(name),
		nodePort = exposedPort,
		pvName = orgName + "-pv",
		path = hostPath,
		genesis = genesisPath,
	)


#if __name__ == "__main__":
#	#ORG_NUMBER = 3
#	podFile = Path('./fabric_cluster.yaml')
#	if podFile.is_file():
#		os.remove('./fabric_cluster.yaml')

#delete the previous exited file	
#	configPeerORGS(1, 2)
#	configPeerORGS(2, 2)
#	configOrdererORGS()
