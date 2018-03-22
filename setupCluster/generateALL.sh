#!/bin/bash +x
PYTHON=python
# CHANNEL_NAME=$1
# : ${CHANNEL_NAME:="mychannel"}

export TOOLS=$PWD/../bin
export CONFIG_PATH=$PWD
export FABRIC_CFG_PATH=$PWD


## Generates Org certs
function generateCerts (){
	CRYPTOGEN=$TOOLS/cryptogen
  # create new material for current config
	$PYTHON transform/assignTenant.py $1

 #  if [[ $OVERRIDE == "true" ]]; then
 #  	# extend material
 #  	$CRYPTOGEN extend --config=./crypto-config.yaml	
 #  else
	# 	$CRYPTOGEN generate --config=./crypto-config.yaml	
	# fi

	# new version support extend, but we use old one for sure
	$CRYPTOGEN generate --config=./crypto-config.yaml
	
	rm crypto-config.yaml

}

function generateKafkaDir() {
  if [[ $OVERRIDE == "true" ]]; then
      return
  fi

  if [ ! -d ./crypto-config/kafka ]; then
      mkdir -p ./crypto-config/kafka
  fi
}

function generateChannelArtifacts() {
	if [ ! -d channel-artifacts ];then
		mkdir channel-artifacts
	fi

	CONFIGTXGEN=$TOOLS/configtxgen
 	$CONFIGTXGEN -profile $PROFILE -outputBlock ./channel-artifacts/genesis.block
# 	$CONFIGTXGEN -profile MultiOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
#	$CONFIGTXGEN -profile MultiOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
# 	$CONFIGTXGEN -profile MultiOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
# 	$CONFIGTXGEN -profile MultiOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP
	
	chmod -R 777 ./channel-artifacts && chmod -R 777 ./crypto-config

  if [[ $OVERRIDE != "true" ]];then
    # copy everything because this is the first time
  	cp ./channel-artifacts/genesis.block ./crypto-config/ordererOrganizations/*
  	# echo "cp -r ./crypto-config $SHARE_FOLDER/ && cp -r ./channel-artifacts $SHARE_FOLDER/"
  	cp -r ./crypto-config $SHARE_FOLDER/ && cp -r ./channel-artifacts $SHARE_FOLDER/
  	# copy script for later use
  	cp -r ./scripts/* $SHARE_FOLDER/channel-artifacts/
  	#$SHARE_FOLDER mouts the remote $SHARE_FOLDER from nfs server
  fi
}

function generateK8sYaml (){
	$PYTHON transform/generate.py --nfs-server $1 --tls-enabled $2 -o $OVERRIDE --version $VERSION --env $ENV --file $CONFIG_FILE --share $SHARE_FOLDER
}

function clean () {
	if [[ $OVERRIDE != "true" ]];then
		rm -rf $SHARE_FOLDER/crypto-config/*
		rm -rf crypto-config
	fi
}

function extend() {
  if [[ $OVERRIDE == "true" ]]; then
    rsync -rv --exclude=*.yaml --ignore-existing ./crypto-config $SHARE_FOLDER/
    rmdir $SHARE_FOLDER/crypto-config/kafka
  fi
}

## Genrates orderer genesis block, channel configuration transaction and anchor peer upddate transactions
##function generateChannelArtifacts () {
##	CONFIGTXGEN=$TOOLS/configtxgen
	
#}

while getopts "c:p:s:t:o:v:e:f:" opt; do
  case "$opt" in
    c)  CONFIG_FILE=$OPTARG
    ;;
    p)  PROFILE=$OPTARG
    ;;
    s)  NSF_SERVER=$OPTARG
    ;;
    t)  TLS_ENABLED=$OPTARG
    ;;
    o)  OVERRIDE=$OPTARG
    ;;
    v)  VERSION=$OPTARG
    ;;
    e)  ENV=$OPTARG
    ;;
    f)  SHARE_FOLDER=$OPTARG
    ;;
  esac
done

# CONFIG_FILE=$1

# PROFILE=$2
: ${PROFILE:=MultiOrgsOrdererGenesis}

# NSF_SERVER=$3
NSF_DEFAULT_SERVER=$(ifconfig | awk '/inet /{print $2}' | grep -v 127.0.0.1 | tail -1)
: ${NSF_SERVER:=$NSF_DEFAULT_SERVER}


# echo "NSF SERVER: $NSF_SERVER, TLS_ENABLED: $TLS_ENABLED"
# echo

clean
generateCerts $CONFIG_FILE 
sleep 1
generateChannelArtifacts
generateKafkaDir
generateK8sYaml $NSF_SERVER $TLS_ENABLED
extend
