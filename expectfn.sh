#!/bin/bash

build(){
  echo "Try to install sshpass:"
  # bash ./sshpass/install-sh  
  cd sshpass
  ./configure
  sudo make install
  # echo "apt-get install sshpass"
  # echo "brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb"
}

if [ ! `command -v sshpass` ];then
  build
  exit
fi

CONFIG=$1
first=${CONFIG%%@*}
last=${CONFIG##*@}
user=${first%%:*}
passwd=${first##*:}
server=${last%%:*}
base_dir=${last##*:}
shift
if [[ $1 == "sync" ]];then
  path=${2:-$PWD}
  echo "Sync folder to server"

  expect << EOF  
  spawn rsync -e "ssh -i /Users/thanhtu/Downloads/azure_cert_node" \
    -chavP --stats --exclude ".git" \
    --exclude "**/node_modules/" \
    --exclude "**/vendor/" \
    --exclude "bin" \
    --exclude "admin/hfc-key-store" \
    --exclude "setupCluster/crypto-config" \
    --exclude "setupCluster/channel-artifacts" \
    $path/ $user@$last
  expect "Enter passphrase"
  send "$passwd\r"
  expect eof
EOF

elif [[ $1 == "build" ]]; then
  #statements
  build
elif [[ $1 == "--" ]];then
  shift
  QUERY="$@"
  expect << EOF
  spawn ssh -i /Users/thanhtu/Downloads/azure_cert_node -t $user@$server "sudo su <<\EOF
$base_dir/fn.sh $QUERY
EOF"
  expect "Enter passphrase"
  send "$passwd\r"
  expect eof
EOF

else
  echo "Unknow command $1" 1>&2
fi