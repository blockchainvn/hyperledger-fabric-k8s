#!/bin/bash

#
# Copyright Agiletech.vn Corp All Rights Reserved
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
ENV=DEV
# Print the usage message
function printHelp () {

  echo "Usage: "
  echo "  $SCRIPT_NAME [-m|--method=] install|instantiate|upgrade|query"
  echo "  $SCRIPT_NAME -h|--help (print this message)"  
  echo

  if [[ ! -z $2 ]]; then
    res=$(printHelp 0 | grep -A2 "\- '$2' \-")
    echo "$res"    
  else      
    echo "      - 'config' - generate channel-artifacts and crypto-config for the network"
    echo "          ./fn.sh config --profile TwoOrgsOrdererGenesis"    
    echo 
    echo "      - 'scale' - scale a deployment of a namespace for the network"
    echo "          ./fn.sh scale --deployment=orderer0-orgorderer-f-1 --min=2 --max=10"    
    echo 
    echo "      - 'tool' - re-build crypto tools with the current version of hyperledger"
    echo "          ./fn.sh tool"
    echo
    echo "      - 'admin' - build admin with namespace and port"
    echo "          ./fn.sh admin --namespace=org1-f-1 --port=30009"
    echo
    echo "      - 'network' - setup the network with kubernetes"
    echo "          ./fn.sh network --mode=[up|down]"
    echo 
    echo "      - 'bash' - go inside bash environment of a container matching selector"
    echo "          ./fn.sh bash cli 'peer channel list'"
    echo
    echo "      - 'channel' - setup channel"
    echo "          ./fn.sh channel --profile TwoOrgsChannel --channel mychannel --namespace org1-f-1 --orderer orderer0.orgorderer-f-1:7050"
    echo
    echo "      - 'install' - install chaincode"
    echo "          ./fn.sh install --channel mychannel --chaincode mycc -v v1"
    echo    
    echo "      - 'instantiate' - instantiate chaincode"
    echo "          ./fn.sh instantiate --orderer orderer0.orgorderer-f-1:7050 --channel mychannel --chaincode mycc --args='{\"Args\":[\"a\",\"10\"]}' -v v1 --policy='OR (Org1.member, Org2.member)'"
    echo
    echo "      - 'upgrade' - upgrade chaincode"
    echo "          ./fn.sh upgrade --orderer orderer0.orgorderer-f-1:7050 --channel mychannel --chaincode mycc --args='{\"Args\":[\"a\",\"10\"]}' -v v2 --policy='OR (Org1.member, Org2.member)'"
    echo
    echo "      - 'query' - query chaincode"    
    echo "          ./fn.sh query --args='{\"Args\":[\"query\",\"a\"]}'"
    echo
    echo "      - 'invoke' - invoke chaincode"    
    echo "          ./fn.sh invoke --args='{\"Args\":[\"set\",\"a\",\"20\"]}'"
  fi

  echo
  echo "  $SCRIPT_NAME method --argument=value"
  
  # default exit as 0
  exit ${1:-0}
}

# verify the result of the end-to-end test
verifyResult() {  
  if [ $1 -ne 0 ] ; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
      exit 1
  fi
}

printCommand(){
  echo -e ""
  echo -e "${BROWN}${BOLD}Command:${NC}"
  echo -e "\t${BLUE}${BOLD}$1${NC}"
  echo -e "${NORMAL}"
}

buildAdmin(){  
  local port=$(getArgument "port")
  cd admin
  echo "Enrolling PeerAdmin..."
  ./peer-admin.sh
  echo
  echo "Building admin image..."
  ./build.sh $NAMESPACE $port
  echo
  echo "Starting admin..."
  kubectl apply -f api-server.yaml
}

setupConfig() {
  local nfs_server=$(getArgument "nfs" ${args[0]})
  local profile=$(getArgument "profile" TwoOrgsOrdererGenesis)
  cd setupCluster
  echo "Creating genesis, profile [$profile]..."
  ./generateALL.sh $nfs_server $profile
  chmod -R 777 /opt/share
  # assign label
  # local master_node=$(kubectl get nodes | awk '$3~/master/{print $1}')
  # if [[ ! -z $master_node ]];then
  #   echo "Assign label org=$NAMESPACE to master node $master_node"
  #   kubectl label nodes $master_node org=$NAMESPACE --overwrite=true
  # fi
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

function buildCryptoTools() {
  cd ${GOPATH}/src/github.com/hyperledger/fabric/
  make configtxgen
  res=$?
  make cryptogen  
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

    echo 
  else
    python transform/run.py
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
  local chaincode_shared_path=${CHAINCODE_PATH/github.com\/hyperledger\/fabric\/peer/\/opt\/share}
  
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
        # nodeSelector:
          # assume all org node can access to docker
          # org: $NAMESPACE
        containers:
          - name: $CHAINCODE
            image: $docker_image
            # inline is more readable            
            command: [ "/bin/bash", "-c", "--" ]            
            args: [ "cp -r /home/$CHAINCODE/* ./ && go build -i && ./$CHAINCODE" ]
            workingDir: /opt/gopath/src/$CHAINCODE
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
                value: /opt/gopath          
              - name: CORE_VM_ENDPOINT
                value: unix:///host/var/run/docker.sock
            imagePullPolicy: Never
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
          org: $NAMESPACE
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
  pod_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/'${args[0]}'/{print $1}' | head -1)
  if [[ $pod_name ]]; then
    if [[ ! -z $QUERY ]]; then      
      kubectl exec -it $pod_name -n $NAMESPACE -- $QUERY
    else
      kubectl exec -it $pod_name -n $NAMESPACE bash
    fi
  else
    echo "Can not find container matching '${args[0]}'"   
  fi    
}

setupChannel() {
  cd setupCluster
  local profile=$(getArgument "profile" TwoOrgsChannel)
  echo "Creating channel artifacts, profile [$profile]..."  
  ../bin/configtxgen -profile $profile -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
  echo

  cp -r ./channel-artifacts /opt/share/
  cli_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/cli/{print $1}' | head -1)
  if [[ ! -z $cli_name ]];then      
    # use fetch channel after that for sure, in case channel has been created
    kubectl exec -it $cli_name -n $NAMESPACE -- peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx 
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer channel create -o $ORDERER_ADDRESS -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx"
    kubectl exec -it $cli_name -n $NAMESPACE -- peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME
    printCommand "${GREEN}kubectl exec -it $cli_name -n $NAMESPACE -- peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_ADDRESS -c $CHANNEL_NAME"
    kubectl exec -it $cli_name -n $NAMESPACE -- peer channel join -b ${CHANNEL_NAME}.block
    printCommand "${GREEN}kubectl exec -it $cli_name -n $NAMESPACE -- peer channel join -b ${CHANNEL_NAME}.block"
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
      createChaincodeDeploymentDev
      untilPod
      untilInstalledChaincode
      sleep 3
    fi

    kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode install -n $CHAINCODE -v $VERSION -p $CHAINCODE_PATH
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
  while [[ $CHAINCODE_STATUS != "true" && $start -lt $wait_timeout ]]; do
      local chaincode_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/'$CHAINCODE'-/{print $1}' | head -1) 
      echo "Waiting for chaincode to be installed on $chaincode_name"
      CHAINCODE_STATUS=$(kubectl exec -it $chaincode_name -n $NAMESPACE -- [ -f $CHAINCODE ] && echo "true")      
      sleep 1
      ((start+=1)) 
      echo "Waiting after $start second, result got: $CHAINCODE_STATUS"
  done

  if [[ $CHAINCODE_STATUS != "true" ]];then
    echo "Waiting for chaincode to be installed timeout"
    exit 1
  fi

  echo "Done chaincode installed"  
}

updateChaincode(){
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
    local POLICY_ARG=
    if [[ ! -z $POLICY ]];then
      POLICY_ARG="-P '$POLICY'"
    fi     

    # ARGS can contain spaces so please surround it by double quote
    # with double quote, we will have it value exactly what we give
    # but when echo it we may see different value
    # if dev, chaincde is created by user so we launch it first at install phrase
    if [[ $ENV == "DEV" ]];then
      # createChaincodeDeploymentDev
      # untilPod
      # untilInstalledChaincode
      # sleep 3
      kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -c "$ARGS" -C $CHANNEL_NAME $POLICY_ARG
    else
      kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -c "$ARGS" -C $CHANNEL_NAME $POLICY_ARG &        
      createChaincodeDeployment $METHOD
      untilPod
    fi
    
    # kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode upgrade -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -c $ARGS -C $CHANNEL_NAME -P '$POLICY'
    # execute first pod is good enough, for api, we get from service
    # chaincode_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/'$CHAINCODE'-/{print $1}' | head -1)    
    # we can use nohup maybe better
    # kubectl exec -it $chaincode_name -n $NAMESPACE -- nohup chaincode -peer.address=$PEER_ADDRESS > /dev/null 2>&1 &
    res=$?  
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -o $ORDERER_ADDRESS -n $CHAINCODE -v $VERSION -c '$ARGS' -C $CHANNEL_NAME $POLICY_ARG"
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
    kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -n $CHAINCODE -c "$ARGS" -C $CHANNEL_NAME
    res=$?  
    printCommand "kubectl exec -it $cli_name -n $NAMESPACE -- peer chaincode $chaincode_method -n $CHAINCODE -c '$ARGS' -C $CHANNEL_NAME"  
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
    cat <<EOF | kubectl $METHOD -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $token_name
  namespace: kube-system

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
    token_check=$(kubectl -n kube-system get secret | grep ${token_name}-token | awk '{print $1}')
  fi  
  echo "Your token: $token_check"
  echo
  kubectl -n kube-system describe secret $token_check | awk '$1~/token/{print $2}'
  echo
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
    args+=($1)
    shift
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
CHANNEL_NAME=$(getArgument "channel" mychannel)
NAMESPACE=$(getArgument "namespace" org1-f-1)
PEER_ADDRESS=$(getArgument "peer" peer0.${NAMESPACE}:7051) 
ORDERER_ADDRESS=$(getArgument "orderer" orderer0.orgorderer-f-1:7050)
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
  *) 
    printHelp 1 ${args[0]}
  ;;
esac
