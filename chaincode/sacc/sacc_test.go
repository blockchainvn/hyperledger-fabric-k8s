package main

import (
  "fmt"
  "github.com/hyperledger/fabric/core/chaincode/shim"
  "testing"
)

func StringArgsToBytesArgs(args []string) [][]byte {
  a := make([][]byte, len(args))
  for k, v := range args {
    a[k] = []byte(v)
  }
  return a
}

func checkInit(t *testing.T, stub *shim.MockStub, args []string) {
  res := stub.MockInit("1", StringArgsToBytesArgs(args))
  if res.Status != shim.OK {
    fmt.Println("Init failed", string(res.Message))
    t.FailNow()
  }
}

func checkState(t *testing.T, stub *shim.MockStub, name string, value string) {
  bytes := stub.State[name]
  if bytes == nil {
    fmt.Println("State", name, "failed to get value")
    t.FailNow()
  }
  if string(bytes) != value {
    fmt.Println("State value", name, "was not", value, "as expected")
    t.FailNow()
  }
}

func checkQuery(t *testing.T, stub *shim.MockStub, names []string, value string) {
  res := stub.MockInvoke("1", StringArgsToBytesArgs(append([]string{"get"}, names...)))
  if res.Status != shim.OK {
    fmt.Println("Query", names, "failed", string(res.Message))
    t.FailNow()
  }

  if res.Payload == nil {
    fmt.Println("Query", names, "failed to get value")
    t.FailNow()
  }

  if string(res.Payload) != value {
    fmt.Println("Query value", names, "was not", value, "as expected")
    t.FailNow()
  }
}

func checkInvoke(t *testing.T, stub *shim.MockStub, args []string) {
  res := stub.MockInvoke("1", StringArgsToBytesArgs(args))
  if res.Status != shim.OK {
    fmt.Println("Invoke", args, "failed", string(res.Message))
    t.FailNow()
  }
}

func Test_Init(t *testing.T) {
  scc := new(SimpleAsset)
  stub := shim.NewMockStub("ex02", scc)
  checkInit(t, stub, []string{"a", "567", "b", "678"})

  checkState(t, stub, "a", "567")
  checkState(t, stub, "b", "678")
}

func Test_Query(t *testing.T) {
  scc := new(SimpleAsset)
  stub := shim.NewMockStub("ex02", scc)
  checkInit(t, stub, []string{"a", "345", "b", "456"})

  checkQuery(t, stub, []string{"a", "b"}, "345,456")
}

func Test_Invoke(t *testing.T) {
  scc := new(SimpleAsset)
  stub := shim.NewMockStub("ex02", scc)
  checkInit(t, stub, []string{})

  checkInvoke(t, stub, []string{"set", "a", "100", "b", "123"})
  checkQuery(t, stub, []string{"a"}, "100")
  checkQuery(t, stub, []string{"b"}, "123")

}

func Benchmark_Invoke(b *testing.B) {
  scc := new(SimpleAsset)
  stub := shim.NewMockStub("ex02", scc)
  stub.MockInit("1", StringArgsToBytesArgs([]string{}))
  for i := 0; i < b.N; i++ {
    args := []string{"set", "a", "100", "b", "123"}
    stub.MockInvoke("1", StringArgsToBytesArgs(args))
  }
}
