Setup 
==============

nfs server

```sh
echo "/opt/share -network 192.168.99.0 -mask 255.255.255.0 -alldirs -maproot=root:wheel" | sudo tee -a /etc/exports
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
