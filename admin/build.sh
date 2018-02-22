IMAGE_NAME='node'
ORDERER_HOST='orderer0.orgorderer-v1:7050'
KEY_STORE_PATH='/hfc-key-store'

NAMESPACE=$1 
PORT=$2
METHOD=$3
org=${4:-$(echo ${NAMESPACE%%-*} | tr [a-z] [A-Z])}
COMMAND=$([[ $METHOD == "create" ]] && echo "yarn && yarn start" || echo "yarn start")
IMAGE_CHECK=$(docker images | grep $IMAGE_NAME)
# use this for multi-node
WORKING_PATH=/opt/share/admin
# WORKING_PATH=$PWD

if [[ -z $IMAGE_CHECK ]];then
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
         imagePullPolicy: Never
         env: 
         - name: PORT
           value: "9000"
         - name: NAMESPACE
           value: "$NAMESPACE"
         - name: KEY_STORE_PATH
           value: "$KEY_STORE_PATH"
         - name: MSP_PATH
           value: "/msp"
         - name: EVENT_HOST
           value: "peer0.${NAMESPACE}:7053"
         - name: PEER_HOST
           value: "peer0.${NAMESPACE}:7051"
         - name: ORDERER_HOST
           value: "$ORDERER_HOST"

         ports:
          - containerPort: 9000
         # command: ["yarn", "yarn start"]
         command: [ "/bin/bash", "-c", "--" ]
         args: [ "./peer-admin.sh $NAMESPACE && $COMMAND" ]
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
             path: /opt/share/crypto-config/peerOrganizations/$NAMESPACE/users/Admin@${NAMESPACE}/msp

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


