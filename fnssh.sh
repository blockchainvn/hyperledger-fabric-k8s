#!/bin/bash

#
# Copyright Agiletech.vn Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# export so other script can access

if [ ! `command -v sshpass` ];then
  echo "Try to install sshpass:"
  echo "apt-get install sshpass"
  echo "brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb"
  exit
fi

CONFIG=$1
shift
QUERY="$@"
first=${CONFIG%%@*}
last=${CONFIG##*@}
user=${first%%:*}
passwd=${first##*:}
server=${last%%:*}
base_dir=${last##*:}

sshpass -p $passwd ssh -t $user@$server 'sudo su <<\EOF
'$base_dir'/fn.sh '$QUERY'
EOF'
