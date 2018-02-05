var program = require("commander");

program
  .version("0.1.0")
  .option("--name, --channel []", "A channel", "mychannel")
  .option("--host, --host []", "Host", "peer0.org1-f-1:7051")
  .option("-u, --user []", "User id", null)
  .parse(process.argv);

var controller = require("./controller")(program.channel, program.host);

var cert = controller.view_ca(program.user);
console.log(cert);
