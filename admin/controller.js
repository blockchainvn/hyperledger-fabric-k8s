/*
* Copyright IBM Corp All Rights Reserved
*
* SPDX-License-Identifier: Apache-2.0
*/
/*
 * Chaincode query
 */
// var fs = require("fs-extra");
var x509 = require("x509");
var Fabric_Client = require("fabric-client");
var path = require("path");

module.exports = function(channelName, address) {
  var fabric_client = new Fabric_Client();
  // const tlsCACertPEM = fs.readFileSync(
  //   "./crypto-config/peerOrganizations/org" +
  //     program.org +
  //     ".example.com/peers/peer0.org" +
  //     program.org +
  //     ".example.com/tls/ca.crt"
  // );

  // setup the fabric network
  var channel = fabric_client.newChannel(channelName);
  // var peer = fabric_client.newPeer(
  //   "grpcs://localhost:" + (program.org == 1 ? 7051 : 8051),
  //   {
  //     pem: tlsCACertPEM.toString(),
  //     "ssl-target-name-override": "peer0.org" + program.org + ".example.com"
  //   }
  // );
  var peer = fabric_client.newPeer("grpc://" + address);
  channel.addPeer(peer);
  console.log("Peer: " + "grpc://" + address);
  var store_path = path.join(__dirname, "hfc-key-store");
  console.log("Store path:" + store_path);

  return {
    get_member_user(user) {
      // create the key value store as defined in the fabric-client/config/default.json 'key-value-store' setting
      return Fabric_Client.newDefaultKeyValueStore({
        path: store_path
      })
        .then(state_store => {
          // assign the store to the fabric client
          fabric_client.setStateStore(state_store);
          var crypto_suite = Fabric_Client.newCryptoSuite();
          // use the same location for the state store (where the users' certificate are kept)
          // and the crypto store (where the users' keys are kept)
          var crypto_store = Fabric_Client.newCryptoKeyStore({
            path: store_path
          });
          crypto_suite.setCryptoKeyStore(crypto_store);
          fabric_client.setCryptoSuite(crypto_suite);

          // get the enrolled user from persistence, this user will sign all requests
          return fabric_client.getUserContext(user, true);
        })
        .then(user_from_store => {
          if (user_from_store && user_from_store.isEnrolled()) {
            console.log("Successfully loaded " + user + " from persistence");
            return user_from_store;
          } else {
            throw new Error(
              "Failed to get " + user + ".... run node register.js -u " + user
            );
          }
        });
    },

    query(user, request) {
      return this.get_member_user(user)
        .then(user_from_store => {
          return channel.queryByChaincode(request);
        })
        .then(query_responses => {
          console.log(
            "Query has completed on channel [" +
              channelName +
              "], checking results"
          );
          // query_responses could have more than one  results if there multiple peers were used as targets
          if (query_responses && query_responses.length == 1) {
            if (query_responses[0] instanceof Error) {
              console.error("error from query = ", query_responses[0]);
            } else {
              // const response = query_responses[0];
              return query_responses[0];
              // console.log("Response is \n", response);
            }
          } else {
            console.log("No payloads were returned from query");
            return null;
          }
        })
        .catch(err => {
          console.error("Failed to query successfully :: " + err);
        });
    }
  };
};
