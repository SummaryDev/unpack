package main

/*
typedef struct {
	char *Name;
	char *Type;
	char *Value;
} InputParam;
*/
import "C"
import (
	"encoding/hex"
	"fmt"
	"log"
	"strings"
	"unsafe"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
)

//export  ProcessLog
func ProcessLog(inAbi *C.char, inData *C.char, inTopic0 *C.char, inTopic1 *C.char,
	inTopic2 *C.char, inTopic3 *C.char, numParams *C.int) **C.InputParam {

	// init the number of returned params
	*numParams = 0

	// abi
	abiString := C.GoString(inAbi)
	log.Printf("From go ProcessLog abi: %s, Size: %d\n", abiString, len(abiString))
	contractABI, err := abi.JSON(strings.NewReader(abiString))
	if err != nil {
		log.Printf("From go ProcessLog Error processing abi\n")
		return nil
	}
	log.Printf("From go ProcessLog Num abi events: %d\n", len(contractABI.Events))

	// topics0 - this is the Event Sig hashed with Keccak256
	topic0 := C.GoString(inTopic0)
	log.Printf("From go ProcessLog topic0: %s, Size: %d\n", topic0, len(topic0))

	// inputs from topics as hashes
	topicHashes := make([]common.Hash, 0, 3)
	var topicsNum = 0

	// topics1
	topic1 := C.GoString(inTopic1)
	if len(topic1) > 0 {
		log.Printf("From go ProcessLog topic1: %s, Size: %d\n", topic1, len(topic1))
		topicHashes = append(topicHashes, common.HexToHash(topic1))
		topicsNum++
	}

	// topics2
	topic2 := C.GoString(inTopic2)
	if len(topic2) > 0 {
		log.Printf("From go ProcessLog topic2: %s, Size: %d\n", topic2, len(topic2))
		topicHashes = append(topicHashes, common.HexToHash(topic2))
		topicsNum++
	}

	// topics3
	topic3 := C.GoString(inTopic3)
	if len(topic3) > 0 {
		log.Printf("From go ProcessLog topic3: %s, Size: %d\n", topic3, len(topic3))
		topicHashes = append(topicHashes, common.HexToHash(topic3))
		topicsNum++
	}
	log.Printf("From go ProcessLog Number of topic inputs is %d\n", topicsNum)

	// data
	data := C.GoString(inData)
	log.Printf("From go ProcessLog data: %s, Size: %d\n", data, len(data))
	dataClean := fromHex(data)
	log.Printf("From go ProcessLog clean data: %s, Size: %d\n", dataClean, len(dataClean))
	dataHex, _ := hex.DecodeString(dataClean)

	// get the matching event from abi using the hash in topics[0]
	eventStruct, err := contractABI.EventByID(common.HexToHash(topic0))
	if err != nil {
		log.Printf("From go ProcessLog Error: Event not found in abi\n")
		return nil
	}
	log.Printf("From go ProcessLog EventByID found event: %s\n", eventStruct.Name)

	// return empty result if anonymous event
	if eventStruct.Anonymous == true {
		log.Printf("From go ProcessLog Event is anonymous: %t, cannot unpack\n", eventStruct.Anonymous)
		return nil
	} else {
		log.Printf("From go ProcessLog Event is anonymous: %t\n", eventStruct.Anonymous)
	}

	// how many total inputs for this Event in abi
	numInputs := len(eventStruct.Inputs)
	log.Printf("From go ProcessLog Number of unputs in abi for this event is: %d\n", numInputs)

	// unpack the inputs from log data
	dataInputs, err := contractABI.Unpack(eventStruct.Name, dataHex)
	if err != nil {
		log.Printf("From go ProcessLog Error unpacking log data\n")
		return nil
	}
	dataInputsNum := len(dataInputs)
	log.Printf("From go ProcessLog Number of Log data items is: %d\n", dataInputsNum)

	// data inputs (non-indexed) + topic inputs (indexed) = total inputs?
	if topicsNum+dataInputsNum != numInputs {
		log.Printf("From go ProcessLog Error number of inputs does't match abi specification\n")
		return nil
	}

	// parse topics into map
	topicsMap := make(map[string]interface{})
	if topicsNum > 0 {
		// create new array of only indexed parameters
		fields := make(abi.Arguments, 0, topicsNum)
		for _, input := range eventStruct.Inputs {
			if input.Indexed {
				fields = append(fields, input)
			}
		}
		err = abi.ParseTopicsIntoMap(topicsMap, fields, topicHashes)
		if err != nil {
			log.Printf("From go ProcessLog Error parsing topics\n")
			return nil
		}
		log.Printf("From go ProcessLog Parsed %d topics\n", len(topicsMap))
		for key, value := range topicsMap {
			log.Printf("From go ProcessLog Topic name: %s, value: %v\n", key, value)
		}
	}

	// go slice to hold input parameters
	params := make([](*C.InputParam), numInputs)

	// loop through all the inputs
	topicIndex := 0
	dataIndex := 0
	for i, input := range eventStruct.Inputs {
		param := C.InputParam{}

		param.Name = C.CString(input.Name)
		param.Type = C.CString(input.Type.String())

		var value interface{}

		// indexed from topics, non-indexed from data
		if input.Indexed {
			log.Printf("From go ProcessLog Indexed INPUT NAME: %s, TYPE: %s, VALUE: %v\n", input.Name, input.Type, topicsMap[input.Name])

			value = topicsMap[input.Name]
			topicIndex++
		} else {
			log.Printf("From go ProcessLog NON-Indexed INPUT NAME: %s, TYPE: %s, VALUE: %v\n", input.Name, input.Type, dataInputs[dataIndex])
			value = dataInputs[dataIndex]
			dataIndex++
		}

		// send all values as strings
		param.Value = C.CString(fmt.Sprintf("%v", value))
		params[i] = &param
	}

	// set num params
	*numParams = C.int(len(params))

	// convert go slice to C pointer array
	ret := C.malloc(C.size_t(len(params)) * C.size_t(unsafe.Sizeof(uintptr(0))))
	pRet := (*[1<<30 - 1]*C.InputParam)(ret)

	for i, item := range params {
		pRet[i] = item
	}
	return (**C.InputParam)(ret)
}

// FromHex returns the bytes represented by the hexadecimal string s.
// s may be prefixed with "0x".
func fromHex(s string) string {
	if has0xPrefix(s) {
		s = s[2:]
	}
	if len(s)%2 == 1 {
		s = "0" + s
	}
	return s
}

// has0xPrefix validates str begins with '0x' or '0X'.
func has0xPrefix(str string) bool {
	return len(str) >= 2 && str[0] == '0' && (str[1] == 'x' || str[1] == 'X')
}

func main() {
}
