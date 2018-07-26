#!/bin/bash
# update and install ntp
sudo yum install epel-release -y
sudo yum update -y
sudo yum install nfs-utils -y
SHARE_FOLDER=/opt/share

if [ ! `command -v go` ];then
	  echo "GO not ready"
	  echo "install golang 1.10.2..."
	  sudo rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
	  sudo curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
	  sudo yum install golang -y
	  echo "install golang 1.10.2 success."
	  sudo go version
fi
if [ ! `command -v docker` ];then
	echo 'Install docker...'
	echo "install docker-ce"
	sudo yum install -y yum-utils device-mapper-persistent-data lvm2
	sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	sudo yum makecache fast
	sudo yum install docker-ce -y
	echo "install docker-compose"
	sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	#Start docker
	sudo systemctl start docker
	sudo systemctl enable docker
	sudo docker --version  
fi
docker --version  

if [ ! `command -v kubectl` ];then
echo 'Install k8s...'
# install k8s
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'

sudo yum install kubelet kubeadm kubectl kubernetes-cni -y

else 
  kubectl cluster-info
fi
sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo swapoff -a
#Open port firewall
sudo firewall-cmd --permanent --add-port=7050/tcp --permanent
sudo firewall-cmd --permanent --add-port=7051/tcp --permanent
sudo firewall-cmd --permanent --add-port=7052/tcp --permanent
sudo firewall-cmd --permanent --add-port=7053/tcp --permanent
sudo firewall-cmd --permanent --add-port=7054/tcp --permanent
sudo firewall-cmd --permanent --add-port=10250/tcp --permanent
sudo firewall-cmd --reload
sudo modprobe br_netfilter
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo mkdir -p /opt/share
sudo chown nfsnobody:nfsnobody /opt/share
service docker restart


