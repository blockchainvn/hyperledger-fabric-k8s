## Setup 
[View detail here](#setup-detail)  
==============

Run  
```sh
./fn.sh help [method]
```

Run fn from ssh mode  
```sh
# synchornize local folder to server
./sshfn.sh user:passwd@server:/path sync localpath
# run command on server
./sshfn.sh user:passwd@server:/path -- command
```

Copy chaincode  
```sh
cp -r ./chaincode /opt/share/channel-artifacts/
```

nfs setup  
```sh
# server
apt-get update
apt-get install nfs-kernel-server -y
mkdir /opt/share
chown mastertest /opt/share
echo "/opt/share    *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
exportfs -a
service nfs-kernel-server start

# client
sudo apt-get update
sudo apt-get install nfs-common -y
mkdir /opt/share
mount -t nfs 10.0.0.4:/opt/share /opt/share
chown -R nobody:nogroup /opt/share/
```

Build admin api images: **optional**  
```sh
# should have a registry instead of saving and loading
# on master node
cd admin
docker build -t hyperledger/admin-api .
docker save hyperledger/admin-api > /opt/share/docker/admin-api.tar
# on slave node
docker load < /opt/share/docker/admin-api.tar
```

## Setup detail
==============

**Step1: Build configtx.yaml, kubernetes files for the network**  
```sh
# change cluster-config file and all kubernetes templates inside setupCluster/templates folder
# view help and hint
./fn.sh help config
# run config
./fn.sh config
# change setupCluster/configtx.yaml to add more Channel configuration 
# default we have MultiOrgsChannel including all organizations
```

**Step2: Start, stop network**  
```sh
# start the network
./fn.sh network
# stop the network
./fn.sh network down
```

**Step3: Start the channel**  
```sh
# run ./fn.sh help channel for more information
./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace as1-v1
# join other organization to channel
./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace idp2-v1 --mode=join
```

**Step4: Install the chaincode**  
```sh
# run ./fn.sh help install for more information
./fn.sh install
```

**Step5: Instantiate/upgrade the chaincode**  
```sh
# run ./fn.sh help instantiate/upgrade for more information
# in production mode, must move peer to current running node so that it can find chaincode image, or save image to share folder
./fn.sh instantiate
```

**Step6: query/invoke the chaincode**  
```sh
# run ./fn.sh help query/invoke for more information
./fn.sh query
```

**Step7: Start api-server**  
```sh
# run ./fn.sh help admin for more information
./fn.sh admin --port 31999
```

**Step8: Scaling**  
```sh
# assign a label to node then move namespace to that label later
./fn.sh assign --node master --org Master
# move all depoyments belong to a namespace
./fn.sh move --namespace kafka --org Master
```


> Alternative way to run at your local machine is using sshfn.sh script
> sshfn.sh using sshpass to automate script at local

**you can use sshpass alone**
```sh
sshpass -p 'password' ssh -t user@host 'sudo su <<\EOF
cd /home/hyperledger-k8s
./fn.sh move --namespace idp1-v1 --org IDP1
./fn.sh move --namespace idp2-v1 --org IDP2
./fn.sh move --namespace idp3-v1 --org IDP3
./fn.sh move --namespace as1-v1 --org AS1
./fn.sh move --namespace as2-v1 --org AS2
./fn.sh move --namespace rp1-v1 --org RP1
./fn.sh move --namespace orgorderer-v1 --org Orderer2
./fn.sh move --namespace kafka --org Master
EOF'
```

