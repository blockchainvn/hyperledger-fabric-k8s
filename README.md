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
./fnssh.sh user:passwd@server:/path sync localpath
# run command on server
./fnssh.sh user:passwd@server:/path -- command
```

Copy chaincode  
```sh
cp -r chaincode /opt/share/channel-artifacts/
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
# on master node
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
./fn.sh channel
```

**Step4: Install the chaincode**  
```sh
# run ./fn.sh help install for more information
./fn.sh install
```

**Step5: Instantiate/upgrade the chaincode**  
```sh
# run ./fn.sh help instantiate/upgrade for more information
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


> Alternative way to run at your local machine is using fnssh.sh script
