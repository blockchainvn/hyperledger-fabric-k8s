# verify the result of the end-to-end test
verifyResult() {  
  if [ $1 -ne 0 ] ; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
      exit 1
  fi
}

printCommand(){
  echo -e ""
  printBoldColor $BROWN "Command:"
  printBoldColor $BLUE "\t$1"  
}

printBoldColor(){
  echo -e "$1${BOLD}$2${NC}${NORMAL}"
}

# # createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
# # Takes an original and modified config, and produces the config update tx which transitions between the two
# createConfigUpdate() {
#   local CHANNEL=$1
#   local ORIGINAL=$2
#   local MODIFIED=$3
#   local OUTPUT=$4
#   # enable debug
#   set -x
#   configtxlator proto_encode --input "${ORIGINAL}" --type common.Config > original_config.pb
#   configtxlator proto_encode --input "${MODIFIED}" --type common.Config > modified_config.pb
#   configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb > config_update.pb
#   configtxlator proto_decode --input config_update.pb  --type common.ConfigUpdate > config_update.json
#   echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
#   configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > "${OUTPUT}"
#   set +x
#   # disable debug
# }

# # fetchChannelConfig <channel_id> <output_json>
# # Writes the current channel config for a given channel to a JSON file
# fetchChannelConfig() {
#   local CHANNEL=$1
#   local OUTPUT=$2
#   local ORDERER_ADDRESS=$3  

#   echo "Fetching the most recent configuration block for the channel"
#   if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
#     set -x
#     peer channel fetch config config_block.pb -o $ORDERER_ADDRESS -c $CHANNEL --cafile $ORDERER_CA
#     set +x
#   else
#     set -x
#     peer channel fetch config config_block.pb -o $ORDERER_ADDRESS -c $CHANNEL --tls --cafile $ORDERER_CA
#     set +x
#   fi

#   echo "Decoding config block to JSON and isolating config to ${OUTPUT}"
#   set -x
#   configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > "${OUTPUT}"
#   set +x
# }




