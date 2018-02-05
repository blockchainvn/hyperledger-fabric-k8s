NAMESPACE=$1
MSP_PATH=/opt/share/crypto-config/peerOrganizations/$NAMESPACE/users/Admin@${NAMESPACE}/msp
  
# create Peer Admin
PRIVATE_KEY=$(ls $MSP_PATH/keystore/*_sk | head -1)
CERTIFICATE=$(cat $MSP_PATH/signcerts/Admin@${NAMESPACE}-cert.pem | sed 's/$/\\r\\n/' | tr -d '\n')
PRIVATE_KEY_NAME=`basename $PRIVATE_KEY | sed 's/_sk//'`

MSPID=$(echo ${NAMESPACE%-*} | sed -e "s/\b\(.\)/\u\1/g")MSP

cat << EOF > hfc-key-store/PeerAdmin
{
  "name": "PeerAdmin",
  "mspid": "$MSPID",
  "roles": null,
  "affiliation": "",
  "enrollmentSecret": "",
  "enrollment": {
    "signingIdentity": "$PRIVATE_KEY_NAME",
    "identity": {
      "certificate": "$CERTIFICATE"
    }
  }
}
EOF

cp $PRIVATE_KEY hfc-key-store/${PRIVATE_KEY_NAME}-priv

echo "created PeerAdmin successfully ..."  
