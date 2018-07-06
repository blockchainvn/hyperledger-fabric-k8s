#!/bin/bash
# update and install ntp
sudo yum update -y

echo 'Install docker...'
sudo yum install docker
#Start docker
sudo systemctl start docker
sudo systemctl enable docker
sudo docker --version  
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

echo 'init kube'
sudo systemctl enable kubelet.service
# --apiserver-advertise-address $(ifconfig eth0 | grep 'inet addr'| cut -d':' -f2 | awk '{print $1}')
kubeadm init --pod-network-cidr 10.244.0.0/16 
read -n 1 -s -r -p "Note join command & Press any key to continue"

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
grep -q -F 'export KUBECONFIG=$HOME/.kube/config' ~/.bashrc || echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc

sysctl net.bridge.bridge-nf-call-iptables=1

# flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# for master
kubectl taint nodes --all node-role.kubernetes.io/master-

# dashboard
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

kubectl get pods --all-namespaces -o wide

else 
  kubectl cluster-info
fi


