package main

import (
	"fmt"
	"io/ioutil"
	"net/http"

	log "github.com/sirupsen/logrus"
)

func handler(w http.ResponseWriter, r *http.Request) {
	content, err := ioutil.ReadFile("index.html")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintf(w, "%s", content)
}

func main() {
	http.HandleFunc("/", handler)
	log.Info("Serving on port :8080")
	http.ListenAndServe(":8080", nil)
}
