Setup 
==============

nfs server
for cluster please run sudo mount /opt/share <master_ip>:/opt/share
```sh
echo "/opt/share -network <master_ip> -mask 255.255.255.0 -alldirs -maproot=root:wheel" | sudo tee -a /etc/exports
sudo nfsd restart
```

Run 

```sh
./fn.sh help
```

Copy chaincode

```sh
cp -r chaincode /opt/share/channel-artifacts/
```
