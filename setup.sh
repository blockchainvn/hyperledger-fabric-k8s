# utf8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# docker ce
if [ ! `command -v docker` ];then
  echo 'Install docker...'
  sudo apt install docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  
  # # latest version that is stable: 17.05
  # curl -O https://download.docker.com/linux/ubuntu/dists/xenial/pool/edge/amd64/docker-ce_17.05.0~ce-0~ubuntu-xenial_amd64.deb
  # sudo dpkg -i docker-ce_17.05.0~ce-0~ubuntu-xenial_amd64.deb
  
  # sudo apt-get install -y \
  #     apt-transport-https \
  #     ca-certificates \
  #     curl \
  #     software-properties-common

  # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # sudo apt-key fingerprint 0EBFCD88

  # docker_version=stable
  # if [ `lsb_release -a 2>&1 | grep 'Release' | awk '$2~/18/{print $2}'` != '' ];then 
  #   docker_version=test
  # fi

  # sudo add-apt-repository \
  #    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  #    $(lsb_release -cs) \
  #    $docker_version"

  # sudo apt-get update

  # sudo apt-get install -y docker-ce

  read -n 1 -s -r -p "Press any key to continue"
else
  docker --version  
fi

# kubenetes
if [ ! `command -v kubectl` ];then
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add 
#   cat <<EOF > /etc/apt/sources.list.d/kubernetes.list  
# deb http://apt.kubernetes.io/ kubernetes-xenial main  
# EOF
#   cat <<EOF > /etc/apt/sources.list.d/kubernetes.list  
# deb https://packages.cloud.google.com/apt/ kubernetes-xenial main  
# EOF

  sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

  # init kube
  swapoff -a
  kubeadm init --pod-network-cidr 10.244.0.0/16 # --apiserver-advertise-address $(ifconfig eth0 | grep 'inet addr'| cut -d':' -f2 | awk '{print $1}')
  read -n 1 -s -r -p "Note join command & Press any key to continue"

  # you can use this script to generate token again
  # kubeadm token create --print-join-command

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  export KUBECONFIG=$HOME/.kube/config
  export KUBECONFIG=$HOME/.kube/config | tee -a ~/.bashrc
  sysctl net.bridge.bridge-nf-call-iptables=1

  # flannel
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  # for master
  kubectl taint nodes --all node-role.kubernetes.io/master-

  # dashboard
  # kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

  # for MACOSX, if not using docker with kubernetes
  # curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl
  # curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.26.1/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
  # minikube start 
  # nohup kubectl proxy --accept-hosts='^.*' --accept-paths='^.*' --address='0.0.0.0' --port=8001 > /dev/null 2>&1 & echo $! > dashboard.pid

  # check pods
  kubectl get pods --all-namespaces -o wide
else 
  kubectl cluster-info
fi



