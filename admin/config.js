module.exports = {
  peerHost: process.env.PEER_HOST || "localhost:7051",
  eventHost: process.env.EVENT_HOST || "localhost:7053",
  ordererHost: process.env.ORDERER_HOST || "localhost:7050",
  caServer: "ca." + process.env.NAMESPACE + ":7054" || "localhost:7054",
  mspID: process.env.MSPID,
  tlsEnabled: process.env.TLS_ENABLED,
  // we use \r\n to put PEM string into process.env, so we have to replace it to newline
  peerPem: process.env.PEER_PEM.replace(/\\r\\n/g, "\r\n"),
  ordererPem: process.env.ORDERER_PEM.replace(/\\r\\n/g, "\r\n")
};
