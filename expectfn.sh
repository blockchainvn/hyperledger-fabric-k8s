#!/bin/bash

build(){
  echo "Try to install expect:"
  cd expect/tcl8.5.15
  ARCH=`uname -s | grep Darwin`
  if [ "$ARCH" != "Darwin" ]; then
    cd unix
  else
    cd macosx
  fi
  # build tcl, move to /usr/local
  ./configure --prefix=/usr/local
  make
  make install
  cd ../../
  # build expect, move to /usr/local
  cd expect5.45
  ./configure --prefix=/usr/local
  make
  make install  
  cd ../
}

if [ ! `command -v expect` ];then
  build  
fi

CONFIG=$1
first=${CONFIG%%@*}
last=${CONFIG##*@}
user=${first%%:*}
keypasswd=${first##*:}
server=${last%%:*}
base_dir=${last##*:}
# SSH_KEY=/Users/thanhtu/Downloads/azure_cert_node
SSH_KEY=${keypasswd%%,*}
if [[ $keypasswd =~ , ]]; then
  passwd=${keypasswd##*,}
fi

shift

if [[ $1 == "sync" ]];then
  path=${2:-$PWD}
  echo "Sync folder to server"

  if [[ ! -z $passwd ]];then
    expect << EOF  
  spawn rsync -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
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
  else
    rsync -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
    -chavP --stats --exclude ".git" \
    --exclude "**/node_modules/" \
    --exclude "**/vendor/" \
    --exclude "bin" \
    --exclude "admin/hfc-key-store" \
    --exclude "setupCluster/crypto-config" \
    --exclude "setupCluster/channel-artifacts" \
    $path/ $user@$last
  fi

elif [[ $1 == "build" ]]; then
  #statements
  build
elif [[ $1 == "--" ]];then
  shift
  # parsing params
  QUERY=  
  while [[ ! -z $1 ]];do     
    if [[ $1 =~ [\ ] ]]; then            
        QUERY="$QUERY '$1'"
    else
        QUERY="$QUERY $1"
    fi  
    shift
  done
  # run expect
  if [[ ! -z $passwd ]];then
    expect << EOF
  spawn ssh -i $SSH_KEY -t $user@$server -o StrictHostKeyChecking=no "sudo su <<\EOF
cd $base_dir
./fn.sh $QUERY
EOF"
  expect "Enter passphrase"
  send "$passwd\r"
  expect eof
EOF
  else
    ssh -i $SSH_KEY -t $user@$server -o StrictHostKeyChecking=no "sudo su <<\EOF
cd $base_dir
./fn.sh $QUERY
EOF"
  fi

else
  echo "Unknow command $1" 1>&2
fi