IMAGE_NAME='hyperledger/admin-api'
NAMESPACE=$1 
PORT=$2
IMAGE_CHECK=$(docker images | grep $IMAGE_NAME)
WORKING_PATH=$PWD

if [[ -z $IMAGE_CHECK ]];then
  echo "Building image $IMAGE_NAME ..."
  echo
  docker build -t $IMAGE_NAME .
fi

: ${NAMESPACE:="default"}
: ${PORT:="30900"}

# create template then you can run it normally
# policy is IfNotPresent because we might create service while image being created
# if set policy to never, we should wait for image ready
cat <<EOF > api-server.yaml
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
        # assume all org node can access to docker
        org: $NAMESPACE
      containers:
       - name: admin
         image: $IMAGE_NAME
         imagePullPolicy: Never
         env: 
         - name:  PORT
           value: "9000"
         ports:
          - containerPort: 9000
         # command: ["yarn", "yarn start"]
         command: [ "/bin/bash", "-c", "--" ]
         args: [ "yarn && yarn start" ]
         # args: [ "while true; do sleep 30; done;" ]                    
         workingDir: /home
         volumeMounts:
          - mountPath: /host/var/run/
            name: run
          - mountPath: /home
            name: working

      restartPolicy: Always

      volumes:
         - name: run
           hostPath:
             path: /var/run
         - name: working
           hostPath:
             path: $WORKING_PATH

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


echo "Created api-server.yaml"