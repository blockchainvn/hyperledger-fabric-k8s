# we can override process env

: ${IMAGE_NAME:='node'}
: ${ORDERER_HOST:='orderer0.orgorderer-v1:7050'}
: ${KEY_STORE_PATH:='/hfc-key-store'}

NAMESPACE=$1 
PORT=$2
METHOD=$3
SHARE_FOLDER=$4
org=${5:-$(echo ${NAMESPACE%%-*} | tr [a-z] [A-Z])}

COMMAND=$([[ $METHOD == "create" ]] && echo "yarn && yarn start" || echo "yarn start")
IMAGE_CHECK=$(docker images | grep $IMAGE_NAME)
# use this for multi-node
WORKING_PATH=$SHARE_FOLDER/admin
# WORKING_PATH=$PWD

image_policy=$([[ $IMAGE_NAME != "node" ]] && echo "Never" || echo "IfNotPresent")

if [[ -z $IMAGE_CHECK ]];then
  echo "Building admin image..."
  if [[ $IMAGE_NAME != "node" ]];then
    echo "Building image $IMAGE_NAME ..."
    echo
    docker build -t $IMAGE_NAME .    
  else    
    docker pull $IMAGE_NAME
  fi
fi

: ${NAMESPACE:="default"}
: ${PORT:="31999"}

ORDERER_NAMESPACE=orgorderer-${NAMESPACE#*-}
MSPID=$(echo ${NAMESPACE%%-*} | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1')MSP

function getFileContentString() {  
  cat $1 | sed 's/$/\\\\r\\\\n/' | tr -d '\n'
}

pod_name=$(kubectl get pod -n $NAMESPACE | awk '$1~/cli/{print $1}' | head -1)
if [[ $pod_name ]]; then
  TLS_ENABLED=$(kubectl describe pods $pod_name -n $NAMESPACE | grep CORE_PEER_TLS_ENABLED | awk '{print $2}')
fi    

if [[ $TLS_ENABLED == "true" ]];then
  PEER_PEM=$(getFileContentString "$SHARE_FOLDER/crypto-config/peerOrganizations/$NAMESPACE/peers/peer0.${NAMESPACE}/tls/ca.crt")
  ORDERER_PEM=$(getFileContentString "$SHARE_FOLDER/crypto-config/ordererOrganizations/$ORDERER_NAMESPACE/orderers/orderer0.${ORDERER_NAMESPACE}/tls/ca.crt")
fi

# each admin only deployed on a server
# create template then you can run it normally
# policy is IfNotPresent because we might create service while image being created
# if set policy to never, we should wait for image ready
cat <<EOF | kubectl $METHOD -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: $NAMESPACE
  name: admin
spec:
  replicas: 1
  # optional, how many revision to be kept for rolling back
  revisionHistoryLimit: 0
  strategy: {}
  template:
    metadata:
      labels:
       app: hyperledger
       role: admin
       org: $NAMESPACE
       name: admin
    spec:
      nodeSelector:
      #   # assume all org node can access to docker
      #   # because we map source code folder to this image so we have to select it
      #   # otherwise we copy it to container and update the images
        org: $org
      containers:
       - name: admin
         image: $IMAGE_NAME
         # resources:
         #  limits:
         #    cpu: "4"          
         #  requests:
         #    cpu: "1"
         imagePullPolicy: $image_policy
         tty: true
         env: 
         - name: PORT
           value: "9000"
         - name: NAMESPACE
           value: "$NAMESPACE"
         - name: KEY_STORE_PATH
           value: "$KEY_STORE_PATH"
         - name: MSP_PATH
           value: "/msp"
         - name: MSPID
           value: "$MSPID"
         - name: EVENT_HOST
           value: "peer0.${NAMESPACE}:7053"
         - name: PEER_HOST
           value: "peer0.${NAMESPACE}:7051"
         - name: ORDERER_HOST
           value: "$ORDERER_HOST"
         - name: TLS_ENABLED
           value: "$TLS_ENABLED"
         - name: PEER_PEM
           value: "$PEER_PEM"
         - name: ORDERER_PEM
           value: "$ORDERER_PEM"

         ports:
          - containerPort: 9000
         # command: ["yarn", "yarn start"]
         command: [ "/bin/bash", "-c", "--" ]
         args: [ "./peer-admin.sh $NAMESPACE && $COMMAND && /bin/bash" ]
         # args: [ "yarn && yarn start" ]
         workingDir: /home
         volumeMounts:
          - mountPath: $KEY_STORE_PATH
            name: hfc-volume
          - mountPath: /host/var/run/
            name: run
          - mountPath: /home
            name: working
          - mountPath: /msp
            name: msp

      restartPolicy: Always

      volumes:
         - name: hfc-volume
           emptyDir: {}

         - name: run
           hostPath:
             path: /var/run
         - name: working
           hostPath:
             path: $WORKING_PATH
         - name: msp
           hostPath:
             path: $SHARE_FOLDER/crypto-config/peerOrganizations/$NAMESPACE/users/Admin@${NAMESPACE}/msp

--- 
apiVersion: v1
kind: Service
metadata:
   namespace: $NAMESPACE
   name: admin
spec:
 selector:
   app: hyperledger
   role: admin
   org: $NAMESPACE
   name: admin
 type: NodePort
 ports:
   - name: endpoint
     protocol: TCP
     port: 9000     
     targetPort: 9000
     nodePort: $PORT

EOF


