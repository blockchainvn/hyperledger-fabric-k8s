## Setup

# [View detail here](#setup-detail)

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

# use alias
alias sshfn='./sshfn.sh blockchainuser:password@server:/home/blockchainuser/hyperledger-k8s'
alias expectfn='./expectfn.sh blockchainuser:key,passphrase@server:/home/blockchainuser/hyperledger-k8s'
```

Copy chaincode

```sh
cp -r ./chaincode /opt/share/channel-artifacts/
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
./fn.sh channel --profile OrgChannel --channel orgchannel --namespace org1-v1
# join other organization to channel
./fn.sh channel --profile OrgChannel --channel orgchannel --namespace org2-v1 --mode=join
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
./fn.sh admin --port 30009 --mode apply
# benchmark the api
wrk -t12 -c5000 -d10s http://localhost:30009/fastquery?chaincode=mycc&channel=mychannel&user=PeerAdmin&method=query&argument=a
```

**Step9: Scaling**

```sh
# move all depoyments belong to a namespace
./fn.sh move --namespace kafka --org Master
```

> Alternative way to run at your local machine is using sshfn.sh script
> sshfn.sh using sshpass to automate script at local

**Command for assign node and move namespace to node**

```sh
./fn.sh assign --node org1 --org ORG1

# move namespaces
./fn.sh move --namespace org1-v1 --org ORG1
#./fn.sh move --namespace kafka --org Master
```
