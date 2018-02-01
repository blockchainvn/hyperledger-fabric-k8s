/*
Copyright IBM Corp. 2016 All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

//WARNING - this chaincode's ID is hard-coded in chaincode_example04 to illustrate one way of
//calling chaincode from a chaincode. If this example is modified, chaincode_example04.go has
//to be modified as well with the new ID of chaincode_example02.
//chaincode_example05 show's how chaincode ID can be passed in as a parameter instead of
//hard-coding.

import (
  "encoding/json"
  "fmt"
  "github.com/hyperledger/fabric/core/chaincode/shim"
  pb "github.com/hyperledger/fabric/protos/peer"
  // "strconv"
)

type CrossChannelResult struct {
  Key   string `json:"key"`
  Value string `json:"value"`
}

func CrossChannelQuery(stub shim.ChaincodeStubInterface,
  queryArgs [][]byte,
  targetChannel string,
  targetChaincode string) ([]byte, error) {
  response := stub.InvokeChaincode(targetChaincode, queryArgs, targetChannel)
  if response.Status != shim.OK {
    err := fmt.Errorf(
      "Failed to invoke chaincode. Got error: %s",
      string(response.Payload))
    return nil, err
  }
  responseAsBytes := response.Payload
  return responseAsBytes, nil
}

func CrossChannelReponse(stub shim.ChaincodeStubInterface, data string) (CrossChannelResult, error) {
  res := CrossChannelResult{}
  err := json.Unmarshal([]byte(data), &res)
  if err != nil {
    return CrossChannelResult{}, err
  }
  return res, nil
}

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
  return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {

  function, args := stub.GetFunctionAndParameters()
  if function == "response" {
    // Make payment of X units from A to B
    return t.response(stub, args)
  } else if function == "query" {
    // the old "Query" is now implemtned in invoke
    return t.query(stub, args)
  }

  return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"delete\" \"query\"")
}

// Transaction makes payment of X units from A to B
func (t *SimpleChaincode) response(stub shim.ChaincodeStubInterface, args []string) pb.Response {

  if len(args) != 1 {
    return shim.Error("Incorrect number of arguments. Expecting 1")
  }
  res, _ := CrossChannelReponse(stub, args[0])
  responseAsBytes, _ := json.Marshal(res)
  return shim.Success(responseAsBytes)
}

// query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

  if len(args) != 4 {
    return shim.Error("Incorrect number of arguments. Expecting 4")
  }

  channelID := args[0]
  chaincodeID := args[1]
  inputFunction := args[2]
  inputArgs := args[3]

  fmt.Printf("channelID: %s, chaincodeID:%s, function:%s, args: %s", channelID, chaincodeID, inputFunction, inputArgs)

  responseAsBytes, err := CrossChannelQuery(stub, [][]byte{[]byte(inputFunction), []byte(inputArgs)}, channelID, chaincodeID)
  if err != nil {
    return shim.Error(err.Error())
  }

  return shim.Success(responseAsBytes)
}

func main() {
  err := shim.Start(new(SimpleChaincode))
  if err != nil {
    fmt.Printf("Error starting Simple chaincode: %s", err)
  }
}
