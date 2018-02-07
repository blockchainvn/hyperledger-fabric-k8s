#### Setup 
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
sudo apt-get install nfs-common
mkdir /opt/share
mount -t nfs 52.230.86.63:/opt/share /opt/share
mount -t nfs
```

Build admin api images: **optional**  
```sh
# on master node
docker save hyperledger/admin-api > /opt/share/docker/admin-api.tar
# on slave node
docker load < /opt/share/docker/admin-api.tar
```

