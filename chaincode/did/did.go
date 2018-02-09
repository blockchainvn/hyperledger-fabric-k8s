package main

import (
	"fmt"
	"strconv"
	"crypto/sha256"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

 
type PerfTestChaincode struct {
}
 
func (t *PerfTestChaincode) Init(stub shim.ChaincodeStubInterface) peer.Response {
    return shim.Success(nil)
}
 
func (t *PerfTestChaincode) Query(stub shim.ChaincodeStubInterface) peer.Response {
    return shim.Success(nil)
}
 
func (t *PerfTestChaincode) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	function, args := stub.GetFunctionAndParameters()
    if function == "writeBlock"{
		return t.writeBlock(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	} else {
		return shim.Error("Invalid invoke function name")
	}
}

func (t *PerfTestChaincode) writeBlock(stub shim.ChaincodeStubInterface, args []string) peer.Response {

	if len(args) < 2 {
		fmt.Printf("Invalid number of argument")
		return shim.Error("Incorrect number of arguments")
	}

	var blockId = args[0]
	var blockData = args[1]
	inLen := len(blockData)
	output := make([]byte, inLen+96)	// original input + 3x sha, 32 bytes each
	copy(output, blockData)

	for i:=1; i < 4; i++ {
		dummy := sha256.New()
		input := string(blockData)+strconv.Itoa(i)
		dummy.Write([]byte(input))
		copy(output[inLen+(32*(i-1)):], dummy.Sum(nil)[:])
	}

	// Write transaction
	err := stub.PutState(blockId, []byte(output))
	if err != nil {
		fmt.Printf("\nCould not write block")
		return shim.Error("Cannot write block")
	}
	
	fmt.Printf("\n")
	return shim.Success(nil)
}

func (t *PerfTestChaincode) query(stub shim.ChaincodeStubInterface, args []string) peer.Response {

	var id, jsonResp string
	var err error

	if len(args) != 1 {
		fmt.Printf("Invalid number of parameters")
		return shim.Error("Invalid number of parameters")
	}
	id = args[0]

	valAsbytes, err := stub.GetState(id)
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get state for " + id + "\"}"
		return shim.Error(jsonResp)
	} else if valAsbytes == nil {
		jsonResp = "{\"Error\":\"Data does not exist: " + id + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valAsbytes)
}
 
func main() {
    err := shim.Start(new(PerfTestChaincode))
    if err != nil {
        fmt.Println("Could not start PerfTestChaincode")
    } else {
        fmt.Println("SampleChaincode successfully started")
    } 
 
}
