package main

import "C"
import (
	"log"
)

//export  ProcessLog
func ProcessLog(text *C.char) {

	goStr := C.GoString(text)
	log.Printf("From go function: %s", goStr)
}

func main() {
}
