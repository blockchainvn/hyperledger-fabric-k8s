var program = require("commander");
var defaultConfig = require("./config");

program
  .version("0.1.0")
  .option("-u, --user []", "User id", "user1")
  .option("--name, --channel []", "A channel", "mychannel")
  .option("--chaincode, --chaincode []", "A chaincode", "origincert")
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

console.log("Config:", config);

var controller = require("./controller")(config);

const request = {
  //targets : --- letting this default to the peers assigned to the channel
  chaincodeId: program.chaincode,
  fcn: program.method,
  args: program.arguments
};

// each method require different certificate of user
controller
  .query(program.user, request)
  .then(ret => {
    console.log(ret.toString());
  })
  .catch(err => {
    console.error(err);
  });
