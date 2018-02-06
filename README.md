Setup 
==============

Generate Hyperledger Fabric config  
```sh
cd setupCluster/genConfig
glide install
go build
./genConfig -Kafka 3 -Orderer 2 -Zookeeper 3 -Orgs "IDP1,IDP2,IDP3,AS1,AS2,RP1" -Peer 2
```

nfs server
for cluster please run sudo mount /opt/share <master_ip>:/opt/share  
```sh
echo "/opt/share -network <master_ip> -mask 255.255.255.0 -alldirs -maproot=root:wheel" | sudo tee -a /etc/exports
sudo nfsd restart
```


Build admin api images: **optional**  
```sh
# on master node
docker save hyperledger/admin-api > /opt/share/docker/admin-api.tar
# on slave node
docker load < /opt/share/docker/admin-api.tar
```

Run  
```sh
./fn.sh help
```

Copy chaincode  
```sh
cp -r chaincode /opt/share/channel-artifacts/
```

In persistent mode when sharing data folder for all pods, reset data using this
```sh
rm -rf /opt/share/ca/* /opt/share/peer/* /opt/share/orderer/* /opt/share/couchdb/*
```

