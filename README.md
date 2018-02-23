## Setup 
[View detail here](#setup-detail)  
==============

Run  
```sh
./fn.sh help [method]
# on nodes just run 
./setup-node.sh 
# then run
kubeadm join --token d326cf.05fa043803407f75 128.199.72.209:6443 --discovery-token-ca-cert-hash
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

# client run with expect to all slave nodes
array="orderer2@52.187.15.1 
nodeu1@52.163.243.228
nodeu2@52.230.2.130
nodeu3@52.237.75.126
nodeu4@52.187.106.1
nodeu5@52.163.125.166
nodeu6@52.230.0.187"
SAVEIFS=$IFS
IFS=$'\n'
array=($array)
IFS=$SAVEIFS
for addr in "${array[@]}";do 
    expect << EOF
    spawn ssh -o StrictHostKeyChecking=no -i /Users/thanhtu/Downloads/azure_cert_node -t $addr "sudo su <<\EOF
    sudo apt-get update
    sudo apt-get install nfs-common -y
    sudo mkdir -p /opt/share
    sudo mount -t nfs 10.0.0.13:/opt/share /opt/share    
EOF"
    expect "Enter passphrase"
    send "123123\r"
    expect eof
EOF
done
```

Build admin api images: **optional, only when image name is not "node"**  
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
# alias expectfn="./expectfn.sh masteru:/Users/thanhtu/Downloads/azure_cert_node,123123@52.187.15.5:/home/hyperledger-k8s"
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

**create hosts file for all nodes, then copy to /opt/share folder**  
```txt
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

10.0.0.5 peer0.idp1-v1
10.0.0.6 peer0.idp2-v1
10.0.0.7 peer0.idp3-v1
10.0.0.8 peer0.as1-v1
10.0.0.9 peer0.as2-v1
10.0.0.10 peer0.rp1-v1
```

**Update hosts file for all nodes
```sh
array="orderer2@52.187.15.1 
nodeu1@52.163.243.228
nodeu2@52.230.2.130
nodeu3@52.237.75.126
nodeu4@52.187.106.1
nodeu5@52.163.125.166
nodeu6@52.230.0.187"
SAVEIFS=$IFS
IFS=$'\n'
array=($array)
IFS=$SAVEIFS
for addr in "${array[@]}";do 
    expect << EOF
    spawn ssh -o StrictHostKeyChecking=no -i /Users/thanhtu/Downloads/azure_cert_node -t $addr "sudo su <<\EOF
    mv /etc/hosts /etc/hosts.bk
    ln -s /opt/share/hosts /etc/hosts 
EOF"
    expect "Enter passphrase"
    send "123123\r"
    expect eof
EOF
done
```

**Command for assign node and move namespace to node**  
```sh
./fn.sh assign --node idp1 --org IDP1
./fn.sh assign --node idp2 --org IDP2
./fn.sh assign --node idp3 --org IDP3
./fn.sh assign --node as1 --org AS1
./fn.sh assign --node as2 --org AS2
./fn.sh assign --node rp1 --org RP1
./fn.sh assign --node orderer2 --org Orderer2
./fn.sh assign --node master --org Master

# move namespaces
./fn.sh move --namespace idp1-v1 --org IDP1
./fn.sh move --namespace idp2-v1 --org IDP2
./fn.sh move --namespace idp3-v1 --org IDP3
./fn.sh move --namespace as1-v1 --org AS1
./fn.sh move --namespace as2-v1 --org AS2
./fn.sh move --namespace rp1-v1 --org RP1
./fn.sh move --namespace orgorderer-v1 --org Orderer2
#./fn.sh move --namespace kafka --org Master
```

**Command for create and join peers to some channels**  
```sh
# create all channel
./fn.sh channel --profile MultiOrgsChannel --channel multichannel --namespace idp1-v1 --orderer orderer0.orgorderer-v1:7050
./fn.sh channel --profile IdpsChannel --channel idpschannel --namespace idp1-v1 --orderer orderer0.orgorderer-v1:7050
./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace as1-v1 --orderer orderer0.orgorderer-v1:7050
./fn.sh channel --profile As2IdpsChannel --channel as2idpschannel --namespace as2-v1 --orderer orderer0.orgorderer-v1:7050
./fn.sh channel --profile Rp1IdpsChannel --channel rp1idpschannel --namespace rp1-v1 --orderer orderer0.orgorderer-v1:7050

# join all channel

./fn.sh channel --profile MultiOrgsChannel --channel multichannel --namespace idp2-v1 --orderer orderer0.orgorderer-v1:7050  --mode join
./fn.sh channel --profile MultiOrgsChannel --channel multichannel --namespace idp3-v1 --orderer orderer0.orgorderer-v1:7050  --mode join
./fn.sh channel --profile MultiOrgsChannel --channel multichannel --namespace as1-v1 --orderer orderer0.orgorderer-v1:7050  --mode join
./fn.sh channel --profile MultiOrgsChannel --channel multichannel --namespace as2-v1 --orderer orderer0.orgorderer-v1:7050  --mode join
./fn.sh channel --profile MultiOrgsChannel --channel multichannel --namespace rp1-v1 --orderer orderer0.orgorderer-v1:7050  --mode join

./fn.sh channel --profile IdpsChannel --channel idpschannel --namespace idp2-v1 --orderer orderer0.orgorderer-v1:7050 --mode join
./fn.sh channel --profile IdpsChannel --channel idpschannel --namespace idp3-v1 --orderer orderer0.orgorderer-v1:7050 --mode join

./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace idp1-v1 --orderer orderer0.orgorderer-v1:7050 --mode join
./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace idp2-v1 --orderer orderer0.orgorderer-v1:7050 --mode join
./fn.sh channel --profile As1IdpsChannel --channel as1idpschannel --namespace idp3-v1 --orderer orderer0.orgorderer-v1:7050 --mode join

./fn.sh channel --profile As2IdpsChannel --channel as2idpschannel --namespace idp1-v1 --orderer orderer0.orgorderer-v1:7050 --mode join
./fn.sh channel --profile As2IdpsChannel --channel as2idpschannel --namespace idp2-v1 --orderer orderer0.orgorderer-v1:7050 --mode join
./fn.sh channel --profile As2IdpsChannel --channel as2idpschannel --namespace idp3-v1 --orderer orderer0.orgorderer-v1:7050 --mode join

./fn.sh channel --profile Rp1IdpsChannel --channel rp1idpschannel --namespace idp1-v1 --orderer orderer0.orgorderer-v1:7050 --mode join
./fn.sh channel --profile Rp1IdpsChannel --channel rp1idpschannel --namespace idp2-v1 --orderer orderer0.orgorderer-v1:7050 --mode join
./fn.sh channel --profile Rp1IdpsChannel --channel rp1idpschannel --namespace idp3-v1 --orderer orderer0.orgorderer-v1:7050 --mode join

# install chaincode for multichannel
./fn.sh install --channel multichannel --namespace idp1-v1 --chaincode multichanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel multichannel --namespace idp2-v1 --chaincode multichanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel multichannel --namespace idp3-v1 --chaincode multichanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel multichannel --namespace as1-v1 --chaincode multichanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel multichannel --namespace as2-v1 --chaincode multichanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel multichannel --namespace rp1-v1 --chaincode multichanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did

./fn.sh instantiate --channel multichannel --namespace idp1-v1 --chaincode multichanneldid --args='{"Args":[]}' -v v1

./fn.sh invoke --namespace idp1-v1 --channel multichannel --chaincode multichanneldid --args='{"Args":["writeBlock","1","20"]}'

./fn.sh query --namespace idp2-v1 --channel multichannel --chaincode multichanneldid --args='{"Args":["query","1"]}'


# install chaincode for idpschannel
./fn.sh install --channel idpschannel --namespace idp1-v1 --chaincode idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel idpschannel --namespace idp2-v1 --chaincode idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel idpschannel --namespace idp3-v1 --chaincode idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did

./fn.sh instantiate --channel idpschannel --namespace idp1-v1 --chaincode idpschanneldid --args='{"Args":[]}' -v v1

./fn.sh invoke --namespace idp1-v1 --channel idpschannel --chaincode idpschanneldid --args='{"Args":["writeBlock","1","20"]}'

./fn.sh query --namespace idp2-v1 --channel idpschannel --chaincode idpschanneldid --args='{"Args":["query","1"]}'


# install chaincode for as1idpschannel
./fn.sh install --channel as1idpschannel --namespace as1-v1 --chaincode as1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel as1idpschannel --namespace idp1-v1 --chaincode as1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel as1idpschannel --namespace idp2-v1 --chaincode as1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel as1idpschannel --namespace idp3-v1 --chaincode as1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did

./fn.sh instantiate --channel as1idpschannel --namespace as1-v1 --chaincode as1idpschanneldid --args='{"Args":[]}' -v v1

./fn.sh invoke --namespace idp1-v1 --channel as1idpschannel --chaincode as1idpschanneldid --args='{"Args":["writeBlock","1","20"]}'

./fn.sh query --namespace idp1-v1 --channel as1idpschannel --chaincode as1idpschanneldid --args='{"Args":["query","1"]}'


# install chaincode for as2idpschannel
./fn.sh install --channel as2idpschannel --namespace as2-v1 --chaincode as2idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel as2idpschannel --namespace idp1-v1 --chaincode as2idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel as2idpschannel --namespace idp2-v1 --chaincode as2idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel as2idpschannel --namespace idp3-v1 --chaincode as2idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did

./fn.sh instantiate --channel as2idpschannel --namespace as2-v1 --chaincode as2idpschanneldid --args='{"Args":[]}' -v v1

./fn.sh invoke --namespace idp1-v1 --channel as2idpschannel --chaincode as2idpschanneldid --args='{"Args":["writeBlock","1","20"]}'

./fn.sh query --namespace idp2-v1 --channel as2idpschannel --chaincode as2idpschanneldid --args='{"Args":["query","1"]}'


# install chaincode for rp1idpschannel
./fn.sh install --channel rp1idpschannel --namespace rp1-v1 --chaincode rp1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel rp1idpschannel --namespace idp1-v1 --chaincode rp1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel rp1idpschannel --namespace idp2-v1 --chaincode rp1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did
./fn.sh install --channel rp1idpschannel --namespace idp3-v1 --chaincode rp1idpschanneldid -v v1 --path github.com/hyperledger/fabric/peer/channel-artifacts/chaincode/did

./fn.sh instantiate --channel rp1idpschannel --namespace rp1-v1 --chaincode rp1idpschanneldid --args='{"Args":[]}' -v v1

./fn.sh invoke --namespace idp1-v1 --channel rp1idpschannel --chaincode rp1idpschanneldid --args='{"Args":["writeBlock","1","20"]}'

./fn.sh query --namespace idp1-v1 --channel rp1idpschannel --chaincode rp1idpschanneldid --args='{"Args":["query","1"]}'

```

