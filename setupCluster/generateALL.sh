#!/bin/bash +x
PYTHON=python
CHANNEL_NAME=$1
: ${CHANNEL_NAME:="mychannel"}

export TOOLS=$PWD/../bin
export CONFIG_PATH=$PWD
export FABRIC_CFG_PATH=$PWD


## Generates Org certs
function generateCerts (){
	CRYPTOGEN=$TOOLS/cryptogen

	$PYTHON transform/assignTenant.py

	$CRYPTOGEN generate --config=./crypto-config.yaml	
	
	
	rm crypto-config.yaml

}

function generateChannelArtifacts() {
	if [ ! -d channel-artifacts ];then
		mkdir channel-artifacts
	fi

	CONFIGTXGEN=$TOOLS/configtxgen
 	$CONFIGTXGEN -profile $PROFILE -outputBlock ./channel-artifacts/genesis.block
# 	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
#	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
# 	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
# 	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP
	
	chmod -R 777 ./channel-artifacts && chmod -R 777 ./crypto-config

	cp ./channel-artifacts/genesis.block ./crypto-config/ordererOrganizations/*
	# echo "cp -r ./crypto-config /opt/share/ && cp -r ./channel-artifacts /opt/share/"
	cp -r ./crypto-config /opt/share/ && cp -r ./channel-artifacts /opt/share/
	#/opt/share mouts the remote /opt/share from nfs server
}

function generateK8sYaml (){
	$PYTHON transform/generate.py $1
}

function clean () {
	rm -rf /opt/share/crypto-config/*
	rm -rf crypto-config
}




## Genrates orderer genesis block, channel configuration transaction and anchor peer upddate transactions
##function generateChannelArtifacts () {
##	CONFIGTXGEN=$TOOLS/configtxgen
	
#}

PROFILE=$1
: ${PROFILE:=TwoOrgsOrdererGenesis}

NSF_SERVER=$2
NSF_DEFAULT_SERVER=$(ifconfig | awk '/inet /{print $2}' | grep -v 127.0.0.1 | tail -1)
: ${NSF_SERVER:=$NSF_DEFAULT_SERVER}



echo "NSF SERVER: $NSF_SERVER"
echo

clean
generateCerts
sleep 1
generateChannelArtifacts
generateK8sYaml $NSF_SERVER
