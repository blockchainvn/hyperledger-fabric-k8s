#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your channel"
echo


ORDERER_CA_DIR=/etc/hyperledger/fabric/orderertls

# verify the result of the end-to-end test
verifyResult () {
  if [ $1 -ne 0 ] ; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
      exit 1
  fi
}

createChannel() {  
  echo "Create channel $CHANNEL_NAME from cli"

  if [[ ! -z $ORDERER_CA ]];then
    peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --tls --cafile $ORDERER_CA
    echo "peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --tls --cafile $ORDERER_CA"
  else 
    peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx
    echo "peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx"
  fi

  res=$?  
  verifyResult $res "Channel creation failed"
  # move channel block back to configx so we can investigate and share between multiple peers
  # for testing purpose
  # mv ${CHANNEL_NAME}.block /etc/hyperledger/configtx/
  echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
  echo
}

joinChannel() {
  
  # if we have PeerAdmin of channel we can use it to fetch again
  if [[ ! -z $ORDERER_CA ]];then
    peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
    echo "peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME --tls --cafile $ORDERER_CA"
  else 
    peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME
    echo "peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME"
  fi
  
  # CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
  peer channel join -b ${CHANNEL_NAME}.block 

  res=$?  
  verifyResult $res "Join channel failed"  
  echo "===================== $CORE_PEER_ADDRESS joined on the channel \"$CHANNEL_NAME\" ===================== "
  sleep $DELAY
  echo  
}

updateChaincode(){

  if [[ ! -z $ORDERER_CA ]];then
    peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE -v $VERSION --tls --cafile $ORDERER_CA -c "$ARGS" -P "$POLICY"
    echo "peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE -v $VERSION --tls --cafile $ORDERER_CA -c '$ARGS' -P '$POLICY'"
  else 
    peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE -v $VERSION -c "$ARGS" -P "$POLICY"
    echo "peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE -v $VERSION -c '$ARGS' -P '$POLICY'"
  fi

  res=$?  
  verifyResult $res "$ACTION chaincode failed"
  echo "===================== $ACTION chaincode \"$CHAINCODE\" successfully ===================== "
  echo
}

invokeChaincode(){
  if [[ ! -z $ORDERER_CA ]];then
    peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE -v $VERSION --tls --cafile $ORDERER_CA -c "$ARGS"
    echo "peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE --tls --cafile $ORDERER_CA -c '$ARGS'"
  else 
    peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE -v $VERSION -c "$ARGS"
    echo "peer chaincode $ACTION -o $ORDERER_ADDRESS -C $CHANNEL_NAME -n $CHAINCODE -c '$ARGS'"
  fi

  res=$?  
  verifyResult $res "$ACTION chaincode failed"
  echo "===================== $ACTION chaincode \"$CHAINCODE\" successfully ===================== "
  echo
}


ACTION="$1"
shift

while getopts "o:C:n:v:c:d:P:m:" opt; do
  case "$opt" in
    o)  ORDERER_ADDRESS=$OPTARG
    ;;
    C)  CHANNEL_NAME=$OPTARG
    ;;
    n)  CHAINCODE=$OPTARG
    ;;
    v)  VERSION=$OPTARG
    ;;
    d)  DELAY=$OPTARG
    ;;
    c)  ARGS=$OPTARG
    ;;
    P)  POLICY=$OPTARG
    ;;
    m)  MODE=$OPTARG
    ;;
  esac
done

: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="1"}
: ${ACTION:="channel"}

echo "Channel name : $CHANNEL_NAME, Action: $ACTION"

if [[ $CORE_PEER_TLS_ENABLED == "true" ]];then
  if [[ ! -d $ORDERER_CA_DIR ]];then
      echo "Directory does not exist: $ORDERER_CA_DIR"
      exit -1
  else
    ORDERER_CA=$(ls $ORDERER_CA_DIR/*.pem | head -1)
  fi
fi

if [[ $ACTION == 'instantiate' || $ACTION == 'upgrade' ]];then
  updateChaincode
elif [[ $ACTION == 'invoke' ]];then
  invokeChaincode
else 
  if [[ $MODE == 'join' ]];then
    echo "Having $CORE_PEER_ADDRESS join the channel..."
    joinChannel
  elif [[ $MODE == 'create' ]];then
    echo "Creating the channel..."
    createChannel
  else     
    echo "Creating & Having $CORE_PEER_ADDRESS join the channel..."
    createChannel  
    joinChannel
  fi
fi

echo
echo "========= All GOOD, network execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
