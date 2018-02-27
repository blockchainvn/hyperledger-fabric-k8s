var program = require("commander");
var defaultConfig = require("./config");

program
  .version("0.1.0")
  .option("-u, --user []", "User id", "user1")
  .option("--name, --channel []", "A channel", "mychannel")
  .option("--chaincode, --chaincode []", "A chaincode", "origincert")
  .option("--host, --host []", "Host", process.env.PEER_HOST)
  .option("--ehost, --event-host []", "Host", process.env.EVENT_HOST)
  .option("--ohost, --orderer-host []", "Host", process.env.ORDERER_HOST)
  .option("-m, --method []", "A method", "getCreator")
  .option(
    "-a, --arguments [value]",
    "A repeatable value",
    (val, memo) => memo.push(val) && memo,
    []
  )
  .parse(process.argv);

const config = Object.assign({}, defaultConfig, {
  channelName: program.channel,
  user: program.user
});

var controller = require("./controller")(config);

var request = {
  //targets: let default to the peer assigned to the client
  chaincodeId: program.chaincode,
  fcn: program.method,
  args: program.arguments
};

// each method require different certificate of user
controller
  .invoke(program.user, request)
  .then(results => {
    console.log(
      "Send transaction promise and event listener promise have completed",
      results
    );
  })
  .catch(err => {
    console.error(err);
  });
