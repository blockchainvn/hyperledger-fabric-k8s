//SPDX-License-Identifier: Apache-2.0
// nodejs server setup

// call the packages we need
const path = require("path");
const express = require("express"); // call express
const bodyParser = require("body-parser");
const fs = require("fs");
const os = require("os");
// const moment = require("moment");
var defaultConfig = require("./config");
const controller_API = require("./controller");

const config = Object.assign({}, defaultConfig, {
  anotherUser: "admin",
  anotherUserSecret: "adminpw",
  user: "admin",
  MSP: defaultConfig.mspID
});

console.log("Config:", config);

const app = express();

app.use(bodyParser.urlencoded({ extended: true }));

// app.get("/test/:id", (req, res) => res.json(req.params.id))
app.use(bodyParser.json());
//app.use(bodyParser.text());

app.post("/send_all/:seq", function(req, res) {
  console.log("req.body:", req.body.message);
  const controller = controller_API(config);
  const request = {
    chaincodeId: "multichanneldid",
    fcn: "writeBlock",
    args: [req.params.seq, req.body.message]
  };

  controller
    .invoke(req.query.user || config.user, request)
    /*
    .then(ret => {
      console.log(ret);
      if(ret[1].event_status === 'VALID'){
        console.log("will move request phase into this");

      }else{
        console.log("error: Something wrong with event/Transaction"+ ret[1].event_status);
      }

      const _request = {
        // targets : '',
        chaincodeId: "multichanneldid",
        chainId: "multichannel",
        fcn: "query",
        args: [req.params.seq]
        // transientMap : '',
        //txId : trxId
      };

      return controller.query("PeerAdmin", _request).then(raw => {
        let prefix = req.params.seq;
        let timestamp = ret[1].time_stamp;
        if(typeof timestamp === 'undefined'){
          timestamp = moment().format('YYMMDDHHmmss.SSS');
        }

        const response = `${timestamp}|${prefix}|${raw.slice(-96,-64).toString('hex')}|${raw.slice(-64,-32).toString('hex')}|${raw.slice(-32).toString('hex')}${os.EOL}`;

        const logFile =
          process.env.NAMESPACE + "." + config.channelName + ".csv";
        fs.appendFile(path.join(__dirname, logFile), response, "utf8", function(
          err
        ) {
          if (err) throw err;
          console.log("Saved!");

        });

        //return { prefix, postfix: data, response };
        return {};
      });
  */
    //return res.json({ message: 'ok na ja' })
    // return res.json(ret);
    //const txId = (Array.isArray(ret)) ? ret.find(({ tx_id }) => tx_id || false) : ''
    //return { txId };

    //var channel = fabric_client.newChannel(config.channelName);

    //return res.json({ ret });
    // })
    //.then(response => res.json(response))
    .then(txid => {
      return res.status(200).json({ txid: txid });
    })
    /*
    .then(({ txId }) => {
        return { txId };
    })
    .then(response => res.json(response))
*/
    .catch(err => {
      return res.status(500).send(err);
    });
});

app.post("/send_idp/:seq", function(req, res) {
  console.log("req.body:", req.body);
  let channelID;
  let chaincodeID;
  let orgs = config.peerHost
    .replace(/(.*)\./, "")
    .replace(/-(.*)/, "")
    .slice(0, 3);

  console.log("orgs:", orgs);

  switch (orgs) {
    case "rp1":
      channelID = "rp1idpschannel";
      chaincodeID = "rp1idpschanneldid";
      break;
    case "as1":
      channelID = "as1idpschannel";
      chaincodeID = "as1idpschanneldid";
      break;
    case "as2":
      channelID = "as2idpschannel";
      chaincodeID = "as2idpschanneldid";
      break;
    case "idp":
      channelID = "idpschannel";
      chaincodeID = "idpschanneldid";
      break;
    default:
      channelID = "multichannel";
      chaincodeID = "multichanneldid";
      break;
  }

  console.log("channelID:", channelID, chaincodeID);
  const controller = controller_API(
    Object.assign({}, config, { channelName: channelID })
  );

  const request = {
    chaincodeId: chaincodeID,
    fcn: "writeBlock",
    args: [req.params.seq, req.body.message]
  };

  // console.log("request:", request);

  controller
    .invoke(req.query.user || config.user, request)
    /*
    .then(ret => {
      if(ret[1].event_status === 'VALID'){
        console.log("will move request phase into this");
      }else{
        console.log("error: Something wrong with event/Transaction"+ ret[1].event_status);
      }
      //return res.json({ message: 'ok na ja' })
      // return res.json(ret);
      //const txId = (Array.isArray(ret)) ? ret.find(({ tx_id }) => tx_id || false) : ''
      //return { txId };

      //var channel = fabric_client.newChannel(config.channelName);

      const _request = {
        // targets : '',
        chaincodeId: chaincodeID, //'multichanneldid',
        chainId: channelID, //'multichannel',
        fcn: "query",
        args: [req.params.seq]
        // transientMap : '',
        //txId : trxId
      };

     // console.log("_request:", _request);

      return controller.query("PeerAdmin", _request).then(raw => {
        let prefix = req.params.seq;
        let timestamp = ret[1].time_stamp;
        if(typeof timestamp === 'undefined'){
          timestamp = moment().format('YYMMDDHHmmss.SSS');
        }

        const response = `${timestamp}|${prefix}|${raw.slice(-96,-64).toString('hex')}|${raw.slice(-64,-32).toString('hex')}|${raw.slice(-32).toString('hex')}${os.EOL}`;

        const logFile = process.env.NAMESPACE + "." + channelID + ".csv";
        fs.appendFile(path.join(__dirname, logFile), response, "utf8", function(
          err
        ) {
          if (err) throw err;
          console.log("Saved!");
        });

        return {};
      });
    })
*/
    //.then(response => res.json(response))
    .then(txid => {
      return res.status(200).json({ txid: txid });
    })
    .catch(err => {
      return res.status(500).send(err);
    });
});

app.get("/viewca", function(req, res) {
  const controller = controller_API(
    Object.assign({}, config, { channelName: req.query.channel })
  );
  const cert = controller.viewca(req.query.user);
  res.json(cert);
});

const queryController = controller_API(
  Object.assign({}, config, { channelName: "mychannel" })
);

app.get("/query", function(req, res) {
  const request = {
    //targets : --- letting this default to the peers assigned to the channel
    chaincodeId: req.query.chaincode,
    fcn: req.query.method,
    args: req.query.arguments
  };

  // each method require different certificate of user
  queryController
    .query(req.query.user || config.user, request)
    .then(ret => {
      // res.json({ result: ret.toString() });
      const retStr = ret.toString();
      res.send(retStr);
      console.log(retStr);
    })
    .catch(err => {
      res.status(500).send(err);
    });
});

app.get("/invoke", function(req, res) {
  const controller = controller_API(
    Object.assign({}, config, { channelName: req.query.channel })
  );
  const request = {
    chaincodeId: req.query.chaincode,
    fcn: req.query.method,
    args: req.query.arguments
  };
  // each method require different certificate of user
  controller
    .invoke(req.query.user || config.user, request)
    .then(ret => {
      res.json(ret);
    })
    .catch(err => {
      res.status(500).send(err);
    });
});

/*
app.post("/send_all/:seq", function(req, res) {
  const request = {
    chaincodeId: "multichanneldid",
    fcn: "writeBlock",
    args: [req.params.seq, req.body.RandNumber]
  };

  controller
    .invoke(req.query.user || config.user, request)
    .then(ret => {
      return res.json({ message: 'ok na ja' })
      //res.json(ret);
    })
    .catch(err => {
      res.status(500).send(err);
    });
});
*/

app.get("/log/:channel", function(req, res) {
  var logFile =
    process.env.NAMESPACE +
    "." +
    (req.params.channel || config.channelName) +
    ".csv";
  res.sendFile(path.join(__dirname, logFile));
});

// Save our port
const port = process.env.PORT || 9000;

// Start the server and listen on port
app.listen(port, "0.0.0.0", () => {
  console.log("Live on port: " + port);
});
