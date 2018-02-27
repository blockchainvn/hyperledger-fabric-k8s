NAMESPACE=$1
  
# create Peer Admin
PRIVATE_KEY=$(ls $MSP_PATH/keystore/*_sk | head -1)
CERTIFICATE=$(cat $MSP_PATH/signcerts/Admin@${NAMESPACE}-cert.pem | sed 's/$/\\r\\n/' | tr -d '\n')
PRIVATE_KEY_NAME=`basename $PRIVATE_KEY | sed 's/_sk//'`
# replace all until no - left
# MSPID=$(echo ${NAMESPACE%%-*} | sed -e "s/\b\(.\)/\u\1/g")MSP
MSPID=$(echo ${NAMESPACE%%-*} | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1')MSP

cat << EOF > /hfc-key-store/PeerAdmin
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

cp $PRIVATE_KEY /hfc-key-store/${PRIVATE_KEY_NAME}-priv

echo "created PeerAdmin successfully ..."  
