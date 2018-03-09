/*
 * Copyright IBM Corp All Rights Reserved
 *
 * SPDX-License-Identifier: Apache-2.0
 */

package main

import (
  "bytes"
  "fmt"
  "github.com/hyperledger/fabric/core/chaincode/shim"
  "github.com/hyperledger/fabric/protos/peer"
)

// SimpleAsset implements a simple chaincode to manage an asset
type SimpleAsset struct {
}

// Init is called during chaincode instantiation to initialize any
// data. Note that chaincode upgrade also calls this function to reset
// or to migrate data.
func (t *SimpleAsset) Init(stub shim.ChaincodeStubInterface) peer.Response {
  // Get the args from the transaction proposal
  args := stub.GetStringArgs()
  // if len(args) != 2 {
  //   return shim.Error("Incorrect arguments. Expecting a key and a value")
  // }

  // // Set up any variables or assets here by calling stub.PutState()

  // We store the key and the value on the ledger
  // err := stub.PutState(args[0], []byte(args[1]))
  result, err := set(stub, args)
  if err != nil {
    return shim.Error(fmt.Sprintf("Failed to create asset: %s", args[0]))
  }
  return shim.Success(result)
}

// Invoke is called per transaction on the chaincode. Each transaction is
// either a 'get' or a 'set' on the asset created by Init function. The Set
// method may create a new asset by specifying a new key-value pair.
func (t *SimpleAsset) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
  // Extract the function and args from the transaction proposal
  fn, args := stub.GetFunctionAndParameters()

  var result []byte
  var err error
  if fn == "set" {
    result, err = set(stub, args)
  } else { // assume 'get' even if fn is nil
    result, err = get(stub, args)
  }
  if err != nil {
    return shim.Error(err.Error())
  }

  // Return the result as success payload
  return shim.Success(result)
}

// Set stores the asset (both key and value) on the ledger. If the key exists,
// it will override the value with the new one
func set(stub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
  var buffer bytes.Buffer
  for i := 0; i < len(args); i = i + 2 {
    value := []byte(args[i+1])
    err := stub.PutState(args[i], value)
    if err != nil {
      return nil, fmt.Errorf("Failed to set asset: %s", args[i])
    }
    if buffer.Len() > 0 {
      buffer.WriteString(",")
    }
    buffer.Write(value)
  }

  return buffer.Bytes(), nil
}

// // Get returns the value of the specified asset key
// func get(stub shim.ChaincodeStubInterface, args []string) (string, error) {
//   if len(args) != 1 {
//     return "", fmt.Errorf("Incorrect arguments. Expecting a key")
//   }

//   value, err := stub.GetState(args[0])
//   if err != nil {
//     return "", fmt.Errorf("Failed to get asset: %s with error: %s", args[0], err)
//   }
//   if value == nil {
//     return "", fmt.Errorf("Asset not found: %s", args[0])
//   }
//   return string(value), nil
// }

// Get returns the list of values of the specified asset keys
func get(stub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
  var buffer bytes.Buffer
  for _, arg := range args {
    value, err := stub.GetState(arg)
    if err != nil {
      return nil, fmt.Errorf("Failed to get asset: %s with error: %s", arg, err)
    }
    if value == nil {
      return nil, fmt.Errorf("Asset not found: %s", arg)
    }
    if buffer.Len() > 0 {
      buffer.WriteString(",")
    }
    buffer.Write(value)
  }
  return buffer.Bytes(), nil
}

// main function starts up the chaincode in the container during instantiate
func main() {
  if err := shim.Start(new(SimpleAsset)); err != nil {
    fmt.Printf("Error starting SimpleAsset chaincode: %s", err)
  }
}
