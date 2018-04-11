#!/bin/bash

#
# Copyright agiletech.vn All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# export so other script can access

# colors
BROWN='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# environment
BASE_DIR=$PWD
DOCKER_COMPOSE_FILE=docker-compose.yml
SCRIPT_NAME=`basename "$0"`

export FABRIC_CFG_PATH=$BASE_DIR/setupCluster

: ${GOPATH:=/opt/gopath}
export GOPATH=$GOPATH
export GOBIN=$GOPATH/bin

# import utils script
. "$BASE_DIR/utils.sh"

# Print the usage message
printHelp () {

  echo $BOLD "Usage: "
  echo "  $SCRIPT_NAME [-m|--method=] install|instantiate|upgrade|query"
  echo "  $SCRIPT_NAME -h|--help (print this message)"  
  echo $NORMAL

  if [[ ! -z $2 ]]; then
    res=$(printHelp 0 | grep -A2 "\- '$2' \-")
    echo "$res"    
  else      
    printBoldColor $BROWN "      - 'config' - generate channel-artifacts and crypto-config for the network"
    printBoldColor $BLUE  "          ./fn.sh config --profile MultiOrgsOrdererGenesis --file cluster-config.yaml [--override true --tls-enabled false --fabric-version 1.0.2 --share /opt/share]"    
    echo 
    printBoldColor $BROWN "      - 'scale' - scale a deployment of a namespace for the network"
    printBoldColor $BLUE  "          ./fn.sh scale --deployment=orderer0-orgorderer-v1 --min=2 --max=10"    
    echo 
    printBoldColor $BROWN "      - 'tool' - re-build crypto tools with the current version of hyperledger"
    printBoldColor $BLUE  "          ./fn.sh tool"
    echo 
    printBoldColor $BROWN "      - 'token' - get token of cluster user"
    printBoldColor $BLUE  "          ./fn.sh token"
    echo
    printBoldColor $BROWN "      - 'admin' - build admin with namespace and port"
    printBoldColor $BLUE  "          ./fn.sh admin --namespace org1-v1 --port 30009 [--mode=up|down]"
    echo
    printBoldColor $BROWN "      - 'network' - setup the network with kubernetes"
    printBoldColor $BLUE  "          ./fn.sh network [apply|down|delete|up] [--namespace org1-v1]"
    echo 
    printBoldColor $BROWN "      - 'bash' - go inside bash environment of a container matching selector"
    printBoldColor $BLUE  "          ./fn.sh bash cli 'peer channel list' --namespace org1-v1"
    echo
    printBoldColor $BROWN "      - 'channel' - setup channel"
    printBoldColor $BLUE  "          ./fn.sh channel --profile MultiOrgsChannel --channel mychannel --namespace org1-v1 --orderer orderer0.orgorderer-v1:7050 [--mode=create|join|up]"
    echo
    printBoldColor $BROWN "      - 'install' - install chaincode"
    printBoldColor $BLUE  "          ./fn.sh install --channel mychannel --namespace org1-v1 --chaincode mycc -v v1 [--no-pod true --path chaincodepath]"
    echo    
    printBoldColor $BROWN "      - 'instantiate' - instantiate chaincode"
    printBoldColor $BLUE  "          ./fn.sh instantiate --channel mychannel --namespace org1-v1 --chaincode mycc --args='{\"Args\":[\"a\",\"10\"]}' -v v1 --policy='OR (Org1.member, Org2.member)'"
    echo
    printBoldColor $BROWN "      - 'upgrade' - upgrade chaincode"
    printBoldColor $BLUE  "          ./fn.sh upgrade --orderer orderer0.orgorderer-v1:7050 --channel mychannel --namespace org1-v1 --chaincode mycc --args='{\"Args\":[\"a\",\"10\"]}' -v v2 --policy='OR (Org1.member, Org2.member)'"
    echo
    printBoldColor $BROWN "      - 'query' - query chaincode"    
    printBoldColor $BLUE  "          ./fn.sh query --namespace org1-v1 --channel mychannel --chaincode mycc --args='{\"Args\":[\"query\",\"a\"]}'"
    echo
    printBoldColor $BROWN "      - 'invoke' - invoke chaincode"    
    printBoldColor $BLUE  "          ./fn.sh invoke --namespace org1-v1 --channel mychannel --chaincode mycc --args='{\"Args\":[\"set\",\"a\",\"20\"]}'"
    echo
    printBoldColor $BROWN "      - 'assign' - assign org label to node"
    printBoldColor $BLUE  "          ./fn.sh assign --node master --org ORG1"
    echo
    printBoldColor $BROWN "      - 'addOrg' - add org to channel"
    printBoldColor $BLUE  "          ./fn.sh addOrg org3-v1 --namespace org1-v1 --channel mychannel"
    echo
    printBoldColor $BROWN "      - 'move' - move namespace to group labeled"
    printBoldColor $BLUE  "          ./fn.sh move --namespace org1-v1 --org ORG1"
    echo
  fi

  echo
  echo "  $SCRIPT_NAME method --argument=value"
  
  # default exit as 0
  exit ${1:-0}
}



buildAdmin(){  
  cd admin
  local port=$(getArgument "port" 31999)   
  # local tlsEnabled=$(getArgument "tls_enabled" false) 
  local method=create
  if [[ $MODE == "up" ]];then
    method=create
  elif [[ $MODE == "down" ]]; then
    method=delete
  else
    # echo "Unknown method $MODE"
    method="$MODE"
    # exit 1
  fi
  #statements  
  echo "Update admin source code"
  rsync -av --progress ./ $SHARE_FOLDER/admin --exclude node_modules
  
  ./build.sh $NAMESPACE $port $method $SHARE_FOLDER # $tlsEnabled
  printCommand "./build.sh $NAMESPACE $port $method"
  echo  
}

setupConfig() {
  
  # check everything is up
  ./setup.sh 

  local nfs_server=$(getArgument "nfs" ${args[0]})
  local profile=$(getArgument "profile" MultiOrgsOrdererGenesis)
  local filePath=$(getArgument "file" cluster-config.yaml)
  local tlsEnabled=$(getArgument "tls_enabled" false)
  local override=$(getArgument "override" false)
  local fabric_version=$(getArgument "fabric_version" 1.0.2)

  cd setupCluster/genConfig

  assertGoInstall
  # install pyyaml for sure
  assertPipInstall
  # if not install vendor then install it
  # if [[ ! -d vendor ]];then
  #   # if [ ! `command -v glide` ]; then        
  #   #   curl https://glide.sh/get | bash    
  #   # fi  
  #   # mkdir $GOBIN
  #   go get gopkg.in/yaml.v2
  #   # glide install    
  # fi
  # echo $BASE_DIR
  # run command
  go run genConfig.go -In ${BASE_DIR}/$filePath -Out ../configtx.yaml -Profile $profile
  printCommand "go run genConfig.go -In ${BASE_DIR}/$filePath -Out ../configtx.yaml -Profile $profile"

  # back to setupCluster folder
  cd ../
  echo "Creating genesis, profile [$profile]..."
  chmod u+x generateALL.sh
  ./generateALL.sh -c ${BASE_DIR}/$filePath -p $profile -s "$nfs_server" -t $tlsEnabled -o $override -v $fabric_version -e $ENV -f $SHARE_FOLDER
  printCommand "./generateALL.sh -c ${BASE_DIR}/$filePath -p $profile -s \"$nfs_server\" -t $tlsEnabled -o $override -v $fabric_version -e $ENV -f $SHARE_FOLDER"
  chmod -R 777 $SHARE_FOLDER

  # assign label, so we can deploy peer to only this node
  local master_node=$(kubectl get nodes | awk '$3~/master/{print $1}')
  if [[ ! -z $master_node ]];then    
    kubectl label nodes $master_node admin=true --overwrite=true
    printCommand "kubectl label nodes $master_node admin=true --overwrite=true"
  fi
}

assignNode(){
  local node=$(getArgument "node")
  local org=$(getArgument "org")
  if [[ -z $node || -z $org ]];then
    echo "Please enter --node and --org params"
    exit 1
  fi
  kubectl label nodes $node org=$org --overwrite=true
  printCommand "kubectl label nodes $node org=$org --overwrite=true"
}

moveToNode(){  
  local org=$(getArgument "org")
  if [[ -z $NAMESPACE || -z $org ]];then
    echo "Please enter --namespace and --org params"
    exit 1
  fi
  local deployments=$(kubectl get deployment -n $NAMESPACE | awk 'NR>1{print $1}')
  kubectl patch deployment $deployments -n $NAMESPACE -p '{"spec":{"template":{"spec":{"nodeSelector":{"org":"'$org'"}}}}}'  
  printCommand "kubectl patch deployment $deployments -n $NAMESPACE -p '{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"org\":\"$org\"}}}}}'"
}

scalePod() {

  local deployment=$(getArgument "deployment")
  local min=$(getArgument "min" 2)
  local max=$(getArgument "max" 10)
  if [[ ! -z $deployment ]];then

  cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: $deployment
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1beta1
    kind: Deployment
    name: $deployment
  minReplicas: $min
  maxReplicas: $max
  metrics:
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 50
EOF
  
    echo "Scaling $deployment with replicas between $min-$max in namespace $NAMESPACE"
    echo
  else
    echo "Please enter deployment name"
  fi

}

assertGoInstall(){
  # install go and fabric library
  if [[ ! -d $GOPATH ]];then
    echo "Installing go for the first time"
    ARCH=`uname -s | grep Darwin`
    if [ "$ARCH" == "Darwin" ]; then
      if [ ! `command -v go` ]; then
        brew install go
      fi
    else
      if [ ! `command -v go` ]; then        
        apt install golang-go -y
      fi  
      apt install libtool libltdl-dev -y
    fi  

    apt install libtool libltdl-dev
    mkdir -p $GOPATH/src    
    cd $GOPATH/src
    # update GOPATH
    echo "export GOPATH=/opt/gopath" | tee ~/.bashrc
    source ~/.bashrc
    mkdir -p github.com/hyperledger
    cd github.com/hyperledger
    git clone https://github.com/hyperledger/fabric.git
    # finally install yaml.v2
    go get gopkg.in/yaml.v2
  fi
}

assertPythonInstall(){
  if [ ! `command -v python` ];then
    ARCH=`uname -s | grep Darwin`
    if [ "$ARCH" == "Darwin" ]; then
      brew install python
    else
      sudo apt-get install python
    fi  
  fi
}

assertPipInstall(){
  # assert python
  assertPythonInstall
  # install pip
  if [ ! `command -v pip` ];then
    ARCH=`uname -s | grep Darwin`
    if [ "$ARCH" != "Darwin" ]; then
      sudo apt-get install python-setuptools -y   
    fi
    sudo easy_install pip
    pip install pyyaml
  fi
}

buildCryptoTools() {
  assertGoInstall
  # install pyyaml for sure
  assertPipInstall
    
  cd $GOPATH/src/github.com/hyperledger/fabric/
  CGO_LDFLAGS_ALLOW="-I.*" make configtxgen
  res=$?
  CGO_LDFLAGS_ALLOW="-I.*" make cryptogen  
  ((res+=$?))
  CGO_LDFLAGS_ALLOW="-I.*" make configtxlator  
  ((res+=$?))
  # check combind of 2 results
  verifyResult $res "Build crypto tools failed"
  echo "===================== Crypto tools built successfully ===================== "
  echo 
  echo "Copying to bin folder of network..."
  echo
  mkdir -p ${BASE_DIR}/bin/
  cp ./build/bin/configtxgen ${BASE_DIR}/bin/
  cp ./build/bin/cryptogen ${BASE_DIR}/bin/
  cp ./build/bin/configtxlator ${BASE_DIR}/bin/
}

setupNetwork() {
  cd setupCluster

  if [[ $MODE == 'down' ]];then    
    python transform/delete.py

    echo "Cleaning chaincode images and container..."
    echo
    # Delete docker containers
    dockerContainers=$(docker ps -a --format '{{.ID}} {{.Names}}' | awk '$2~/^dev-peer/{print $1}')
    if [ "$dockerContainers" != "" ]; then     
      docker rm -f $dockerContainers > /dev/null
    fi

    chaincodeImages=$(docker images --format '{{.ID}} {{.Repository}}' | awk '$2~/^dev-peer/{print $1}')  
    if [ "$chaincodeImages" != "" ]; then     
      docker rmi $chaincodeImages > /dev/null
    fi  

    echo "Cleaning persistent volumes, including share and data folders"
    rm -rf $SHARE_FOLDER/ca/* $SHARE_FOLDER/peer/* $SHARE_FOLDER/orderer/* $SHARE_FOLDER/couchdb/* $SHARE_FOLDER/kafka/*
    rm -rf /data/ca/* /data/peer/* /data/orderer/* /data/couchdb/* /data/kafka/*
    echo 
  else
    # can run up, delete an organization
    python transform/run.py $MODE $NAMESPACE
    printCommand "python transform/run.py $MODE $NAMESPACE"
  fi
}

signConfigBlock() {
  # let's assumes config envelope is fixed
  local cli_name=$(kubectl get pod -n $1 | awk '$1~/cli/{print $1}' | head -1)
  if [[ -z $cli_name ]];then
    echo -e "Cli pod not found, you must run ${BOLD}./fn network --namespace $1${NORMAL} first!"
    exit 1
  fi
  kubectl exec -it $cli_name -n $1 -- peer channel signconfigtx -f channel-artifacts/config_update_as_envelope.pb -o $ORDERER_ADDRESS
  printCommand "kubectl exec -it $cli_name -n $1 -- peer channel signconfigtx -f channel-artifacts/config_update_as_envelope.pb -o $ORDERER_ADDRESS"
}

addOrganization() {
  # get org name space
  local ORG_NAMESPACE=${args[0]}
  local MSPID=$(echo ${ORG_NAMESPACE%%-*} | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1')MSP
  local pid=$(ps ax | grep configtxlator | grep -v grep | awk '{print $1}')
  # if not have configtxlator then start it and wait 3 seconds
  if [[ -z $pid ]];then
    ${BASE_DIR}/bin/configtxlator start &
    sleep 3
    # no need to run [while loop], 3 seconds are good enough, if not then the second time will be success as well
    pid=$(ps ax | grep configtxlator | grep -v grep | awk '{print $1}')
  fi
  
  local port=$(lsof -Pan -p $pid -i | grep -o '*:[0-9]\+' | cut -d':' -f 2)
  local configtxlator_base="http://127.0.0.1:$port"
    
  cli_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/cli/{print $1}' | head -1)
  if [[ ! -z $cli_name ]];then   
    # go to channel-artifacts folder
    cd $SHARE_FOLDER/channel-artifacts
    # check jq program regradless os
    checkJQProgram
    # Step1: fetch config block
    kubectl exec -it $cli_name -n $NAMESPACE -- peer channel fetch config config_block.pb -o $ORDERER_ADDRESS -c $CHANNEL_NAME
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer channel fetch config config_block.pb -o $ORDERER_ADDRESS -c $CHANNEL_NAME"
    # Step2: move config block to share folder
    kubectl exec -it $cli_name -n $NAMESPACE -- mv config_block.pb channel-artifacts/
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- mv config_block.pb channel-artifacts/"
    # Step3: calculate changes
    # already export FABRIC_CFG_PATH in current session
    ${BASE_DIR}/bin/configtxgen -printOrg $MSPID > ${MSPID}.json    
    curl -X POST --data-binary @config_block.pb $configtxlator_base/protolator/decode/common.Block > config_block.json
    jq .data.data[0].payload.data.config config_block.json > config.json
    jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"'$MSPID'":.[1]}}}}}' config.json ${MSPID}.json > updated_config.json
    curl -X POST --data-binary @config.json $configtxlator_base/protolator/encode/common.Config > config.pb
    curl -X POST --data-binary @updated_config.json $configtxlator_base/protolator/encode/common.Config > updated_config.pb
    curl -X POST -F original=@config.pb -F updated=@updated_config.pb $configtxlator_base/configtxlator/compute/update-from-configs -F channel=$CHANNEL_NAME > config_update.pb
    curl -X POST --data-binary @config_update.pb $configtxlator_base/protolator/decode/common.ConfigUpdate > config_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' > config_update_as_envelope.json
    curl -X POST --data-binary @config_update_as_envelope.json $configtxlator_base/protolator/encode/common.Envelope > config_update_as_envelope.pb

    # Step3: sign new config
    # we need to get all msp in the write_set config then do the signing
    mspids=($(jq '.payload.data.config_update.write_set.groups.Application.groups' config_update_as_envelope.json  | jq 'keys[]'))
    for i in "${mspids[@]}";do
      # include quote last character    
      signConfigBlock $(echo ${i:1:${#i}-5} | tr A-Z a-z)-${NAMESPACE#*-}    
    done 

    # Step3: update new config
    kubectl exec -it $cli_name -n $NAMESPACE -- peer channel update -f channel-artifacts/config_update_as_envelope.pb -o $ORDERER_ADDRESS -c $CHANNEL_NAME
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer channel update -f channel-artifacts/config_update_as_envelope.pb -o $ORDERER_ADDRESS -c $CHANNEL_NAME"

    res=$?  
    verifyResult $res "Add organization failed"
    echo "===================== Add organization successfully ===================== "
    echo
  else
    echo "Cli pod not found" 1>&2
  fi
}

# this one is for development phrase
createChaincodeDeploymentDev() {
  # DEV mode can instantiate until peer success 
  # we copy the chaincode from mapping path to prevent re-create
  # in the production mode, it is installed in product folder
  # if [[ $METHOD == "apply" ]];then
  kubectl delete deployment $CHAINCODE -n $NAMESPACE # --grace-period=0 --force
  DEPLOYMENT_STATUS=$(kubectl get deployment $CHAINCODE -n $NAMESPACE | awk 'NR>1{print $1}' | head -1)
  while [[ $DEPLOYMENT_STATUS == $CHAINCODE ]]; do
    echo "Waiting for Pod $CHAINCODE to be deleted"      
    DEPLOYMENT_STATUS=$(kubectl get deployment $CHAINCODE -n $NAMESPACE | awk 'NR>1{print $1}' | head -1)
    sleep 1
    ((start+=1))      
    echo "Waiting after $start second."
  done
  # fi

  local docker_image=hyperledger/fabric-ccenv:x86_64-1.0.2
  local chaincode_shared_path=${CHAINCODE_PATH/github.com\/hyperledger\/fabric\/peer/$SHARE_FOLDER}
  echo "Chaincode shared path: $chaincode_shared_path"
  echo
  local org=$(getArgument "org" $(echo ${NAMESPACE%%-*} | tr [a-z] [A-Z]))
  cat <<EOF | kubectl create -f -
  apiVersion: extensions/v1beta1
  kind: Deployment
  metadata:
    name: $CHAINCODE
    namespace: $NAMESPACE
  spec:
    replicas: 1
    strategy: {}
    template:
      metadata:
        labels:
          app: chaincode
          channel: $CHANNEL_NAME
      spec:
        nodeSelector:
          # assume all org node can access to docker
          # org: $NAMESPACE
          org: $org
        containers:
          - name: $CHAINCODE
            image: $docker_image
            # inline is more readable            
            command: [ "/bin/bash", "-c", "--" ]            
            args: [ "cp -r /home/$CHAINCODE/* ./ && go build -i && ./$CHAINCODE" ]
            workingDir: $GOPATH/src/$CHAINCODE
            volumeMounts:
              - mountPath: /host/var/run/
                name: run
              - mountPath: /home/$CHAINCODE
                name: chaincode
            env:
              - name: CORE_PEER_ID
                value: $CHAINCODE
              - name: CORE_PEER_ADDRESS
                value: $PEER_ADDRESS
              - name: CORE_CHAINCODE_ID_NAME
                value: ${CHAINCODE}:${VERSION}    
              - name: GOPATH
                value: $GOPATH          
              - name: CORE_VM_ENDPOINT
                value: unix:///host/var/run/docker.sock
            imagePullPolicy: IfNotPresent
        restartPolicy: Always
        volumes:
         - name: run
           hostPath:
             path: /var/run
         - name: chaincode
           hostPath:
             path: $chaincode_shared_path
EOF
  
  sleep 3
  echo "$METHOD chaincode Deployment successfully"
  # do we need to delete docker container ?

}      

createChaincodeDeployment() {

  # if [[ $ENV == "DEV" ]];then
  #   createChaincodeDeploymentDev $1
  #   return 0
  # fi

  untilImage

  local METHOD=${1:-create}

  if [[ $METHOD == "apply" ]];then
    kubectl delete deployment $CHAINCODE -n $NAMESPACE # --grace-period=0 --force
    DEPLOYMENT_STATUS=$(kubectl get deployment $CHAINCODE -n $NAMESPACE | awk 'NR>1{print $1}' | head -1)
    while [[ $DEPLOYMENT_STATUS == $CHAINCODE ]]; do
      echo "Waiting for Pod $CHAINCODE to be deleted"      
      DEPLOYMENT_STATUS=$(kubectl get deployment $CHAINCODE -n $NAMESPACE | awk 'NR>1{print $1}' | head -1)
      sleep 1
      ((start+=1))      
      echo "Waiting after $start second."
    done
  fi

  local docker_image=$(docker images | grep "${CHAINCODE}-${VERSION}" | awk '{print $1}' | head -1)
  local org=$(getArgument "org" $(echo ${NAMESPACE%%-*} | tr [a-z] [A-Z]))
  cat <<EOF | kubectl create -f -
  apiVersion: extensions/v1beta1
  kind: Deployment
  metadata:
    name: $CHAINCODE
    namespace: $NAMESPACE
  spec:
    replicas: 1
    strategy: {}
    template:
      metadata:
        labels:
          app: chaincode
      spec:
        nodeSelector:
          # assume all org node can access to docker
          # org: $NAMESPACE
          # deploy at current node that run the script
          org: $org
        containers:
          - name: $CHAINCODE
            # tty: true
            image: $docker_image
            # inline is more readable            
            command: [ "chaincode -peer.address=$PEER_ADDRESS" ]            
            env:
              - name: CORE_CHAINCODE_ID_NAME
                value: ${CHAINCODE}:${VERSION}
            imagePullPolicy: Never
        restartPolicy: Always
EOF
  
  sleep 3
  echo "$METHOD chaincode Deployment successfully"
  # do we need to delete docker container ?

}

untilImage() {
  local wait_timeout=${1:-$TIMEOUT}
  local start=0
  local IMAGE_STATUS=
  while [[ -z $IMAGE_STATUS && $start -lt $wait_timeout ]]; do
      echo "Waiting for docker image [${CHAINCODE}-${VERSION}] to be created"      
      IMAGE_STATUS=$(docker images | grep "${CHAINCODE}-${VERSION}" | awk '{print $1}')
      sleep 1
      ((start+=1))      
      echo "Waiting after $start second."
  done

  if [[ -z $IMAGE_STATUS ]];then
    echo "Waiting for Image timeout" 
    exit 1
  fi
}

untilPod() {
  local wait_timeout=${1:-$TIMEOUT}
  local start=0  
  local POD_STATUS=
  while [[ -z $POD_STATUS && $start -lt $wait_timeout ]]; do
      echo "Waiting for pod [$CHAINCODE] to start completion. Status = ${POD_STATUS}"
      POD_STATUS=$(kubectl get pod -n $NAMESPACE | awk '$1~/'$CHAINCODE'-/{print $1}' | head -1)
      sleep 1
      ((start+=1)) 
      echo "Waiting after $start second."
  done

  if [[ -z $POD_STATUS ]];then
    echo "Waiting for Pod timeout"
    exit 1
  fi
}

bashContainer () {    
  local pod_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/'${args[0]}'/{print $1}' | head -1)
  if [[ $pod_name ]]; then
    local container=
    if [[ ! -z ${args[1]} ]];then
      container="-c ${args[1]} "
    fi    
    if [[ ! -z $QUERY ]]; then      
      kubectl exec -it $pod_name -n $NAMESPACE $container -- $QUERY
      printCommand "kubectl exec -it $pod_name -n $NAMESPACE $container-- $QUERY"
    else
      kubectl exec -it $pod_name -n $NAMESPACE $container bash
    fi
  else
    echo "Can not find container matching '${args[0]}'"   
  fi    
}

setupChannel() {
  cd setupCluster
  local profile=$(getArgument "profile" MultiOrgsChannel)
  if [[ $MODE != "join" ]];then
    echo "Creating channel artifacts, profile [$profile]..."  
    ../bin/configtxgen -profile $profile -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
    printCommand "../bin/configtxgen -profile $profile -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}"
    echo
    cp -r ./channel-artifacts $SHARE_FOLDER/
  fi

  cli_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/cli/{print $1}' | head -1)
  if [[ ! -z $cli_name ]];then      
    # use fetch channel after that for sure, in case channel has been created
    # kubectl exec -it $cli_name -n $NAMESPACE -- peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx 
    # printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx"
    # kubectl exec -it $cli_name -n $NAMESPACE -- peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME
    # printCommand "${GREEN}kubectl exec -it $cli_name -n $NAMESPACE -- peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME"
    # kubectl exec -it $cli_name -n $NAMESPACE -- peer channel join -b ${CHANNEL_NAME}.block
    # printCommand "${GREEN}kubectl exec -it $cli_name -n $NAMESPACE -- peer channel join -b ${CHANNEL_NAME}.block"

    kubectl exec -it $cli_name -n $NAMESPACE -- ./channel-artifacts/cli.sh channel -C $CHANNEL_NAME -o $ORDERER_ADDRESS -m $MODE
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- ./channel-artifacts/cli.sh channel -C $CHANNEL_NAME -o $ORDERER_ADDRESS -m $MODE"

    res=$?  
    verifyResult $res "Setup channel failed"
    echo "===================== Setup channel successfully ===================== "
    echo
  else
    echo "Cli pod not found" 1>&2
  fi
}

installChaincode() {
  cli_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/cli/{print $1}' | head -1)
  if [[ ! -z $cli_name ]];then    

    if [[ $ENV == 'DEV' ]];then
      local no_pod=$(getArgument "no_pod")
      if [[ -z $no_pod ]];then
        createChaincodeDeploymentDev
        untilPod
        untilInstalledChaincode
        sleep 3
      fi
    fi

    kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode install -n $CHAINCODE -v $VERSION -p $CHAINCODE_PATH
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode install -n $CHAINCODE -v $VERSION -p $CHAINCODE_PATH"
    res=$?  
    verifyResult $res "Install chaincode failed"
    echo "===================== Install chaincode successfully ===================== "
    echo
  else
    echo "Cli pod not found" 1>&2
  fi
}

untilInstalledChaincode(){  
  local wait_timeout=${1:-$TIMEOUT}
  local start=0  
  local CHAINCODE_STATUS=  
  # do not use bash to get the result, it is very strange
  local chaincode_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/'$CHAINCODE'-/{print $1}' | head -1) 
  echo "Waiting for chaincode to be installed on $chaincode_name"
  printCommand "kubectl exec -it $chaincode_name -n $NAMESPACE -- bash -c 'if [[ -f $CHAINCODE ]];then echo true;fi' | sed $'s/[^[:print:]"'\\t'"]//g'"
  # Remove everything except the printable characters
  while [[ $CHAINCODE_STATUS != true && $start -lt $wait_timeout ]]; do            
      CHAINCODE_STATUS=$(kubectl exec -it $chaincode_name -n $NAMESPACE -- bash -c 'if [[ -f '$CHAINCODE' ]];then echo true;fi' | sed $'s/[^[:print:]\t]//g')      
      sleep 1
      ((start+=1)) 
      echo "Waiting after $start second, result got: $CHAINCODE_STATUS"
  done

  if [[ $CHAINCODE_STATUS != true ]];then
    echo "Waiting for chaincode to be installed timeout"
    exit 1
  fi

  echo "Done chaincode installed"  
}

updateChaincode(){
  # in production mode, please scale cli and peer on the same node
  local chaincode_method=${1:-upgrade}
  local METHOD=apply
  if [[ $chaincode_method == "instantiate" ]];then
    METHOD=create
  elif [[ $chaincode_method != "upgrade" ]];then
    echo "Don't know method $chaincode_method"
    exit 1
  fi  

  cli_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/cli/{print $1}' | head -1)
  if [[ ! -z $cli_name ]];then   
    # local SUFFIX_ARG=

    # local orderer_cert=$(echo $(kubectl exec -it $cli_name -n $NAMESPACE -- bash -c "ls /etc/hyperledger/fabric/orderertls/*.pem" 2>&1 | awk '$1~/.pem/{print $1}'))
    # if [[ ! -z $orderer_cert ]];then
    #   SUFFIX_ARG="--tls true --cafile $orderer_cert"
    # fi
     

    # if [[ ! -z $POLICY ]];then
    #   SUFFIX_ARG="$SUFFIX_ARG -P '$POLICY'"
    # fi     

    # ARGS can contain spaces so please surround it by double quote
    # with double quote, we will have it value exactly what we give
    # but when echo it we may see different value
    # if dev, chaincde is created by user so we launch it first at install phrase
    if [[ $ENV == "DEV" ]];then
      # createChaincodeDeploymentDev
      # untilPod
      # untilInstalledChaincode
      # sleep 3
      # kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -c "$ARGS" -C $CHANNEL_NAME $SUFFIX_ARG

      kubectl exec -it $cli_name -n $NAMESPACE -- ./channel-artifacts/cli.sh $chaincode_method -c "$ARGS" -C $CHANNEL_NAME -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -P "$POLICY"
      

    else
      # kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -c "$ARGS" -C $CHANNEL_NAME $SUFFIX_ARG &        
      kubectl exec -it $cli_name -n $NAMESPACE -- ./channel-artifacts/cli.sh $chaincode_method -c "$ARGS" -C $CHANNEL_NAME -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -P "$POLICY" 
      # createChaincodeDeployment $METHOD
      # untilPod
    fi
    
    # kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode upgrade -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -c $ARGS -C $CHANNEL_NAME -P '$POLICY'
    # execute first pod is good enough, for api, we get from service
    # chaincode_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/'$CHAINCODE'-/{print $1}' | head -1)    
    # we can use nohup maybe better
    # kubectl exec -it $chaincode_name -n $NAMESPACE -- nohup chaincode -peer.address=$PEER_ADDRESS > /dev/null 2>&1 &
    res=$?  
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- ./channel-artifacts/cli.sh $chaincode_method -c '$ARGS' -C $CHANNEL_NAME -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -P '$POLICY'"
    verifyResult $res "$chaincode_method chaincode failed"
    echo "===================== $chaincode_method chaincode successfully ===================== "    
    echo
  else
    echo "Cli pod not found" 1>&2
  fi
}

execChaincode() {
  local chaincode_method=${1:-query}  
  if [[ ! $chaincode_method =~ ^query|invoke$ ]];then
    echo "Don't know method $chaincode_method"
    exit 1
  fi  
  cli_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/cli/{print $1}' | head -1)
  if [[ ! -z $cli_name ]];then

    if [[ $chaincode_method == "query" ]];then
      kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -n $CHAINCODE -c "$ARGS" -C $CHANNEL_NAME
      printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -n $CHAINCODE -c '$ARGS' -C $CHANNEL_NAME"  
    else      
      kubectl exec -it $cli_name -n $NAMESPACE -- ./channel-artifacts/cli.sh $chaincode_method -c "$ARGS" -C $CHANNEL_NAME -o $ORDERER_ADDRESS -n $CHAINCODE
      printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- ./channel-artifacts/cli.sh $chaincode_method -c "$ARGS" -C $CHANNEL_NAME -o $ORDERER_ADDRESS -n $CHAINCODE"
    fi

    res=$?      
    verifyResult $res "$chaincode_method chaincode failed"
    echo "===================== $chaincode_method chaincode successfully ===================== "    
    echo
  else
    echo "Cli pod not found" 1>&2
  fi  
}

getToken(){
  local token_name=$(getArgument "token" admin-user)
  local token_check=$(kubectl -n kube-system get secret | grep ${token_name}-token | awk '{print $1}')
  if [[ -z $token_check ]];then
    echo "Creating new one..."
    cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $token_name
  namespace: kube-system
EOF

    cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: $token_name
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: $token_name
  namespace: kube-system
EOF
    
    echo "Patching dashboard to use nodePort 30000"
    kubectl patch service kubernetes-dashboard -n kube-system -p '{"spec":{"type":"NodePort","ports":[{"nodePort":30000,"port":443,"protocol":"TCP","targetPort":8443}]}}'    
    token_check=$(kubectl -n kube-system get secret | grep ${token_name}-token | awk '{print $1}')
  fi 

  if [[ ! -z $token_check ]];then
    echo "Your token: $token_check"
    echo
    kubectl -n kube-system describe secret $token_check | awk '$1~/token/{print $2}'
    printCommand "kubectl -n kube-system describe secret $token_check | awk '$1~/token/{print $2}'"
    echo
  else
    echo "Not found ${token_name}-token"
  fi
}

# declare MYMAP 
# val='{"Args":["a","10"]}'
# MYMAP[foo]=$val
# echo ${MYMAP[foo]}
# exit

# Get a value:
getArgument() {   
  # indirection, use string as name of variable
  local key="args_${1/-/_}"
  # return default value from $2 if not existed
  echo ${!key:-$2}  
}


# check first param is method
if [[ $1 =~ ^[a-z] ]]; then 
  METHOD=$1
  shift
fi

# use [[ ]] we dont have to quote string
args=()
case "$METHOD" in
  bash|config)
    while [[ ! -z $2 ]];do
      if [[ ${1:0:2} == '--' ]]; then
        KEY=${1/--/}    
        if [[ $KEY =~ ^([a-zA-Z_-]+)=(.+) ]]; then         
            declare "args_${BASH_REMATCH[1]/-/_}=${BASH_REMATCH[2]}"
        else
            declare "args_${KEY/-/_}=$2"        
            shift
        fi    
      else 
        args+=($1)
      fi
      shift
    done
    QUERY="$@"    
  ;;
  *) 
    # normal processing
    while [[ $# -gt 0 ]] ; do                
      if [[ ${1:0:2} == '--' ]]; then
        KEY=${1/--/}        
        # if [[ $KEY == 'help' ]]; then
        #   printHelp 0 $2
        if [[ $KEY =~ ^([a-zA-Z_-]+)=(.+) ]]; then         
            declare "args_${BASH_REMATCH[1]/-/_}=${BASH_REMATCH[2]}"
        else
            declare "args_${KEY/-/_}=$2"        
            shift
        fi    
      else 
        case "$1" in
          -h|\?)            
            printHelp 0 $2
          ;;
          -v)
            declare "args_version=$2"
            shift
          ;;
          -n)
            declare "args_namespace=$2"
            shift
          ;;
          *)  
            args+=($1)
            # echo "Invalid OPTION $1"
          ;;  
        esac    
      fi 
      shift
    done 
  ;; 
esac

# process methods and arguments, by default first is channel and next is org_id
ENV=$(getArgument "env" PROD)
SHARE_FOLDER=$(getArgument "share" /opt/share)
CHANNEL_NAME=$(getArgument "channel" mychannel)
NAMESPACE=$(getArgument "namespace")
PEER_ADDRESS=$(getArgument "peer" peer0.${NAMESPACE}:7051) 
# by default get ternant by deleting the leading string of namespace
ORDERER_ADDRESS=$(getArgument "orderer" orderer0.orgorderer-${NAMESPACE#*-}:7050)
CHAINCODE=$(getArgument "chaincode" mycc)
CHAINCODE_PATH=$(getArgument "path" github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/sacc)
ARGS=$(getArgument "args" '{"Args":[]}')
POLICY=$(getArgument "policy")
VERSION=$(getArgument "version" v1)
MODE=$(getArgument "mode" ${args[0]:-up})
TIMEOUT=$(getArgument "timeout" 120)

# for convenient
# echo "args: "$(getArgument "query" "select * from")
case "${METHOD}" in   
  bash)
    bashContainer
  ;;
  tool)
    buildCryptoTools
  ;;
  channel)
    setupChannel
  ;;
  install)
    installChaincode
  ;;
  scale)
    scalePod
  ;;
  admin)
    buildAdmin
  ;;
  token)
    getToken
  ;;
  config)
    setupConfig
  ;;
  network)
    setupNetwork
  ;;
  addOrg)
    addOrganization
  ;;
  instantiate)
    updateChaincode instantiate
  ;;
  upgrade)
    updateChaincode upgrade
  ;;
  query)
    execChaincode query
  ;; 
  invoke)
    execChaincode invoke
  ;;   
  assign)
    assignNode
  ;;
  move)
    moveToNode
  ;;
  *) 
    printHelp 1 ${args[0]}
  ;;
esac
