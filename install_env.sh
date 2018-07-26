#!/usr/bin/env bash
set -e 

GO_HOME=/opt/gopath
GO_ROOT=/usr/local/go
FABRIC_VERSION=v1.1.0-preview
function install {
	yum install epel-release -y
	sudo yum update -y
	#installOtherForBuild
	installGo
	installDockerCE
	installDockerCompose
	#installFabric
	#buildCryptoTools
	#installK8s
}

function installFabric {
	if [[ ! -d $GOPATH/src/github.com/hyperledger ]];then
	    cd $GOPATH/src
	    mkdir -p github.com/hyperledger
	    cd github.com/hyperledger
	    echo 'Clone fabric version ' $FABRIC_VERSION
	    git clone -b release-1.1 https://github.com/hyperledger/fabric.git 
  	fi
}

function installNode {
	if [ ! `command -v node` ];then

		sudo curl -sL https://rpm.nodesource.com/setup_8.x | bash -
		sudo yum install nodejs -y
		curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
		sudo yum install yarn -y
	fi
	node --version
	npm --version
	yarn --version
}

function installK8s {
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
	sudo swapoff -a
	else 
	  kubectl cluster-info
	fi
}

function buildCryptoTools {
	cd $GOPATH/src/github.com/hyperledger/fabric/
	make configtxgen
	make cryptogen
	make configtxlator
	echo "===================== Crypto tools built successfully ===================== "
	echo 
	echo "Copying to bin /usr/local/bin"
	echo
	mkdir -p ${BASE_DIR}/bin/
	cp ./build/bin/* /usr/local/bin/
}


function installOtherForBuild {
	sudo yum install gcc-c++ make python-pip python-devel libtool-ltdl libtool-ltdl-devel python-setuptools -y
	sudo pip install pyyaml
	sudo pip install jinja2
	sudo go get gopkg.in/yaml.v2
	sudo yum install git -y
}

function installDockerCE {
	if [ ! `command -v docker` ];then
		echo 'Install docker-ce'
		sudo yum install -y yum-utils device-mapper-persistent-data lvm2
		sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
		sudo yum makecache fast
		sudo yum install docker-ce -y
		echo 'Install docker-ce success'
	fi
	docker -v
}

function installDockerCompose {
	if [ ! `command -v docker-compose` ];then
		echo 'Install docker-compose'
		sudo curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
		sudo chmod +x /usr/local/bin/docker-compose
		echo 'Install docker-compose success'
	fi
	docker-compose -v
}

function installGo {
	if [ ! `command -v go` ];then
		echo 'Install go'
		echo 'Create go path' $GO_HOME
	    if [ ! -d $GO_HOME ]; then
	        sudo mkdir $GO_HOME
	        sudo mkdir -p $GO_HOME/{src,pkg,bin}
	    else
	        sudo mkdir -p $GO_HOME/{src,pkg,bin}
	    fi

		rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
		curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
		sudo yum install golang -y
		export GOPATH=$GO_HOME
		sudo grep -q -F 'export GOPATH=/opt/gopath' $HOME/.bashrc || echo 'export GOPATH=/opt/gopath' >> $HOME/.bashrc
	    sudo grep -q -F 'export GOROOT=/usr/lib/golang' $HOME/.bashrc || echo 'export GOROOT=/usr/lib/golang' >> $HOME/.bashrc
	    sudo grep -q -F 'export PATH=$PATH:$GOROOT/bin' $HOME/.bashrc || echo 'export PATH=$PATH:$GOROOT/bin' >> $HOME/.bashrc
	    sudo grep -q -F 'export PATH=$PATH:$GOPATH/bin' $HOME/.bashrc || echo 'export PATH=$PATH:$GOPATH/bin' >> $HOME/.bashrc  
	    echo ''
	    echo 'Install success golang'
	fi
	go version
}

install
