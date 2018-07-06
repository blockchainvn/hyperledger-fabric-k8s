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

else 
  kubectl cluster-info
fi


