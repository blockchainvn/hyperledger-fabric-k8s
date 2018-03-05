var defaultConfig = require("./config");
const controller_API = require("./controller");

const config = Object.assign({}, defaultConfig, {
  anotherUser: "admin",
  anotherUserSecret: "adminpw",
  user: "admin",
  MSP: defaultConfig.mspID
});

// console.log("Config:", config);

const controllerMap = new Map();

module.exports = {
  getInstance(channelName) {
    if (!controllerMap.has(channelName)) {
      controllerMap.set(
        channelName,
        controller_API(Object.assign({}, config, { channelName: channelName }))
      );
    }
    return controllerMap.get(channelName);
  },
  getConfig() {
    return config;
  }
};
