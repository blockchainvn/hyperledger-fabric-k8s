import os
import time
import config as tc

### order of run ###

#### orderer
##### namespace(org)
###### single orderer

#### peer
##### namespace(org)
###### ca
####### single peer

def deleteOrderers(path):
  orgs = sorted(os.listdir(path))
  for org in orgs:
    orgPath = os.path.join(path, org)
    namespaceYaml = os.path.join(orgPath, org + "-namespace.yaml" ) #orgYaml namespace.yaml

    for orderer in os.listdir(orgPath + "/orderers"):
      ordererPath = os.path.join(orgPath + "/orderers", orderer)
      ordererYaml = os.path.join(ordererPath, orderer + ".yaml")
      checkAndDelete(ordererYaml)

    time.sleep(1)
    checkAndDelete(namespaceYaml)




def deletePeers(path):
  orgs = sorted(os.listdir(path))
  for org in orgs:
    orgPath = os.path.join(path, org)

    namespaceYaml = os.path.join(orgPath, org + "-namespace.yaml" ) # namespace.yaml
    caYaml = os.path.join(orgPath, org + "-ca.yaml" ) # ca.yaml
    cliYaml = os.path.join(orgPath, org + "-cli.yaml" ) # cli.yaml  

    for peer in sorted(os.listdir(orgPath + "/peers")):
      peerPath = os.path.join(orgPath + "/peers", peer)
      peerYaml = os.path.join(peerPath, peer + ".yaml")
      checkAndDelete(peerYaml)

    checkAndDelete(cliYaml)
    checkAndDelete(caYaml)

    time.sleep(1)               # keep namespace alive until every resources have been destroyed
    checkAndDelete(namespaceYaml)

def deleteKafkas(path):
  for i in range(0, 4):
      kafkaYaml = os.path.join(path, "kafka" + str(i) + "-kafka.yaml")
      checkAndDelete(kafkaYaml)

  for i in range(0, 3):
      zkYaml = os.path.join(path, "zookeeper" + str(i) + "-zookeeper.yaml")
      checkAndDelete(zkYaml)

  namespaceYaml = os.path.join(path, "kafka-namespace.yaml")
  time.sleep(1)     
  checkAndDelete(namespaceYaml)

def checkAndDelete(f):
  if os.path.isfile(f):
    os.system("kubectl delete -f " + f)

if __name__ == "__main__":  
  if len(os.listdir(tc.KAFKA)) > 1:
    deleteKafkas(tc.KAFKA) 
  deleteOrderers(tc.ORDERER)
  deletePeers(tc.PEER)      

