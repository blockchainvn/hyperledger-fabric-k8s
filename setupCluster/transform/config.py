from string import Template
#from pathlib import Path
import re
import string
import os

TestDir = './dest/'
PORTSTARTFROM = 30001
GAP = 100  #interval for worker's port
NSF_SERVER = '192.168.99.1'
VERSION = '1.0.2'
TLS_ENABLED = 'false'

def render(src, dest, **kw):
	t = Template(open(src, 'r').read())	
	options = dict(version=VERSION, tlsEnabled=TLS_ENABLED, **kw)    
	with open(dest, 'w') as f:
		f.write(t.substitute(**options))

	##### For testing ########################
	##testDest = dest.split("/")[-1]	##
	##with open(TestDir+testDest, 'w') as d:##
	##d.write(t.substitute(**kw))      	##
	##########################################
def getTemplate(templateName):
	baseDir = os.path.dirname(__file__)
	configTemplate = os.path.join(baseDir, "../templates/" + templateName)
	return configTemplate

def getAddressSegment(name):
	pattern = re.compile('(\d+)$')
	result = re.search(pattern, name.split("-")[0])
	return (int(result.group(0)) -1 if result else 0) * GAP	


# create org/namespace 
# copy to "/opt/share/" => need to map to nfs
def configORGS(name, path, orderer0): # name means if of org, path describe where is the namespace yaml to be created. 	
	namespaceTemplate = getTemplate("template_namespace.yaml")
	hostPath = path.replace("transform/../", "/opt/share/")
	render(namespaceTemplate, path + "/" + name + "-namespace.yaml", 
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


		render(cliTemplate, path + "/" + name + "-cli.yaml", 
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
		addressSegment = getAddressSegment(name)	
		# each oganization should have unique ip, so ip + port should be unique
		exposedPort = PORTSTARTFROM + addressSegment

		caTemplate = getTemplate("template_ca.yaml")
		
		tlsCertTemplate = '/etc/hyperledger/fabric-ca-server-config/{}-cert.pem'
		tlsKeyTemplate = '/etc/hyperledger/fabric-ca-server-config/{}'
		caPathTemplate = 'ca/'
		cmdTemplate =  ' fabric-ca-server start --ca.certfile /etc/hyperledger/fabric-ca-server-config/{}-cert.pem --ca.keyfile /etc/hyperledger/fabric-ca-server-config/{} -b admin:adminpw -d '

		skFile = ""
		for f in os.listdir(path+"/ca"):  # find out sk!
			if f.endswith("_sk"):
				skFile = f
			
		render(caTemplate, path + "/" + name + "-ca.yaml", 
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

def generateYaml(member, memberPath, flag):
	if flag == "/peers":
		configPEERS(member, memberPath)
	else:
		configORDERERS(member, memberPath) 
	

# create peer/pod
def configPEERS(name, path): # name means peerid.
	configTemplate = getTemplate("template_peer.yaml")
	hostPath = path.replace("transform/../", "/opt/share/")
	mspPathTemplate = 'peers/{}/msp'
	tlsPathTemplate =  'peers/{}/tls'
	#mspPathTemplate = './msp'
	#tlsPathTemplate = './tls'
	nameSplit = name.split(".")
	peerName = nameSplit[0]
	orgName = nameSplit[1]

	# addressSegment = (int(orgName.split("-")[0].split("org")[-1]) - 1) * GAP
	addressSegment = getAddressSegment(orgName)
	##peer from like this peer 0##
	peerOffset = int((peerName.split("peer")[-1])) * 4
	exposedPort1 = PORTSTARTFROM + addressSegment + peerOffset + 1
	exposedPort2 = PORTSTARTFROM + addressSegment + peerOffset + 2
	exposedPort3 = PORTSTARTFROM + addressSegment + peerOffset + 3
	
	render(configTemplate, path + "/" + name + ".yaml", 
		namespace = orgName,
		podName = peerName + "-" + orgName,
		peerID  = peerName,
		org = orgName, 
		corePeerID = name,
		peerAddress = name + ":7051",
		peerCCAddress = name + ":7052",
		peerGossip = name  + ":7051",
		localMSPID = orgName.split('-')[0].capitalize()+"MSP",
		mspPath = mspPathTemplate.format(name),
		tlsPath = tlsPathTemplate.format(name),
		nodePort1 = exposedPort1,
		nodePort2 = exposedPort2,
		nodePort3 = exposedPort3,
    pvName = orgName + "-pv",
    path = hostPath
	)


# create orderer/pod
def configORDERERS(name, path): # name means ordererid
	configTemplate = getTemplate("template_orderer.yaml")
	hostPath = path.replace("transform/../", "/opt/share/")
	genesisPath = os.path.dirname(os.path.dirname(hostPath))
	mspPathTemplate = 'orderers/{}/msp'
	tlsPathTemplate = 'orderers/{}/tls'

	nameSplit = name.split(".")
	ordererName = nameSplit[0]
	orgName = nameSplit[1]
	
	ordererOffset = int(ordererName.split("orderer")[-1])
	exposedPort = 32700 + ordererOffset

	render(configTemplate, path + "/" + name + ".yaml", 
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
