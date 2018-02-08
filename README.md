## Setup 
[View detail here](#setup-detail)  
==============

Run  
```sh
./fn.sh help [method]
```

Run fn from ssh mode from sshfn and expectfn  
```sh
# synchornize local folder to server
./sshfn.sh user:passwd@server:/path sync [localpath]
./expectfn.sh user:key,passphrase@server:/path sync [current]
# run command on server
./sshfn.sh user:passwd@server:/path -- command
./expectfn.sh user:key,passphrase@server:/path -- command
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

# client run with expect
expect << EOF
  spawn ssh -o StrictHostKeyChecking=no -i /Users/thanhtu/Downloads/azure_cert_node -t nodeu2@52.230.2.130 "sudo su <<\EOF
sudo apt-get update
sudo apt-get install nfs-common -y
mkdir /opt/share
mount -t nfs 10.0.0.13:/opt/share /opt/share
chown -R nobody:nogroup /opt/share/
EOF"
  expect "Enter passphrase"
  send "123123\r"
  expect eof
EOF
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

**Step3: Labeling nodes**  
```sh
# assign a label to node then move namespace to that label later
./fn.sh assign --node master --org Master
```

**Step4: Start the channel**  
```sh
# run ./fn.sh help channel for more information
./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace as1-v1
# join other organization to channel
./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace idp2-v1 --mode=join
```

**Step5: Install the chaincode**  
```sh
# run ./fn.sh help install for more information
./fn.sh install
```

**Step6: Instantiate/upgrade the chaincode**  
```sh
# run ./fn.sh help instantiate/upgrade for more information
# in production mode, must move peer to current running node so that it can find chaincode image, or save image to share folder
./fn.sh instantiate
```

**Step7: query/invoke the chaincode**  
```sh
# run ./fn.sh help query/invoke for more information
./fn.sh query
```

**Step8: Start api-server**  
```sh
# run ./fn.sh help admin for more information
./fn.sh admin --port 31999
```

**Step9: Scaling**  
```sh
# move all depoyments belong to a namespace
./fn.sh move --namespace kafka --org Master
```


> Alternative way to run at your local machine is using sshfn.sh script
> sshfn.sh using sshpass to automate script at local

**you can use sshpass| expect alone**  
```sh
# sshpass command
sshpass -p 'password' ssh -t user@host 'sudo su <<\EOF
cd /home/hyperledger-k8s
./fn.sh command
EOF'

# expect command
expect << EOF
  spawn ssh -o StrictHostKeyChecking=no -i key_file -t user@server "sudo su <<\EOF
cd /home/hyperledger-k8s
./fn.sh command
EOF"
  expect "Enter passphrase"
  send "123123\r"
  expect eof
EOF
```

**Command for assign node and move namespace to node**  
```sh
./fn.sh assign --node ipd1 --org IDP1
./fn.sh assign --node ipd2 --org IDP2
./fn.sh assign --node ipd3 --org IDP3
./fn.sh assign --node as1 --org AS1
./fn.sh assign --node as2 --org AS2
./fn.sh assign --node rp1 --org RP1
./fn.sh assign --node orderer2 --org Orderer2
./fn.sh assign --node master --org Master

./fn.sh move --namespace idp1-v1 --org IDP1
./fn.sh move --namespace idp2-v1 --org IDP2
./fn.sh move --namespace idp3-v1 --org IDP3
./fn.sh move --namespace as1-v1 --org AS1
./fn.sh move --namespace as2-v1 --org AS2
./fn.sh move --namespace rp1-v1 --org RP1
./fn.sh move --namespace orgorderer-v1 --org Orderer2
./fn.sh move --namespace kafka --org Master
```

