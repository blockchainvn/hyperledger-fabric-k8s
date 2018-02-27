var program = require("commander");
var defaultConfig = require("./config");
const controller_API = require("./controller");

program
  .version("0.1.0")
  .option("--name, --channel []", "A channel", "mychannel")
  .option("--host, --host []", "Host", "peer0.org1-f-1:7051")
  .option("-u, --user []", "User id", null)
  .parse(process.argv);

const config = Object.assign({}, defaultConfig, {
  channelName: program.channel,
  user: program.user
});

var controller = controller_API(config);

var cert = controller.viewca(program.user);
console.log(cert);
