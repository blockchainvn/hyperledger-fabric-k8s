# utf8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# docker ce
if [ ! `command -v docker` ];then
  sudo apt-get install \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  sudo apt-key fingerprint 0EBFCD88

  sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"

  sudo apt-get update

  sudo apt-get install docker-ce

  read -n 1 -s -r -p "Press any key to continue"
else
  docker --version  
fi

# kubenetes
if [ ! `command -v kubectl` ];then
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list  
deb http://apt.kubernetes.io/ kubernetes-xenial main  
EOF

  sudo apt-get update  
  sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

else 
  kubectl cluster-info
fi

