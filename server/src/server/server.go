package main

import (
	"bytes"
	"encoding/json"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/russross/blackfriday"
	"golang.org/x/net/websocket"
)

type message struct {
	Title      string    `json:"title"`
	Path       string    `json:"path"`
	Contents   string    `json:"contents"`
	ReceivedAt time.Time `json:"received_at"`
}

var c = make(chan message)
var data = message{"autopreview", "", "Welcome to autopreview!", time.Now()}

func send(ws *websocket.Conn, data message) error {
	return websocket.JSON.Send(ws, data)
}

func socket(ws *websocket.Conn) {
	if err := send(ws, data); err != nil {
		log.Println(err)
		return
	}

	for {
		if err := send(ws, <-c); err != nil {
			log.Println(err)
			break
		}
	}
}

func handle(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		index, err := Index()
		if err != nil {
			log.Println(err)
			status := http.StatusInternalServerError
			http.Error(w, http.StatusText(status), status)
			return
		}
		w.Header().Add("Content-Type", "text/html; charset=utf-8")
		io.Copy(w, index)
	case http.MethodPut:
		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			log.Println(err)
			status := http.StatusInternalServerError
			http.Error(w, http.StatusText(status), status)
			return
		}

		var parsed message
		if err := json.Unmarshal(body, &parsed); err != nil {
			log.Println(err)
			status := http.StatusBadRequest
			http.Error(w, http.StatusText(status), status)
			return
		}

		buf := bytes.NewBufferString(parsed.Contents)
		parsed.Contents = string(blackfriday.MarkdownCommon(buf.Bytes()))
		parsed.ReceivedAt = time.Now()

		data = parsed
		log.Printf("Got new contents for %s (%d bytes).\n", data.Title, len(data.Contents))
		c <- data
	case http.MethodDelete:
		log.Println("Received stop request; exiting...")
		os.Exit(0)
	default:
		status := http.StatusMethodNotAllowed
		http.Error(w, http.StatusText(status), status)
	}
}

type RelativeFileSystem struct {
	base *string
}

func (rfs RelativeFileSystem) Open(name string) (http.File, error) {
	return http.Dir(*rfs.base).Open(name)
}

func main() {
	http.HandleFunc("/", handle)
	http.Handle("/api", websocket.Handler(socket))
	http.Handle("/static/", http.StripPrefix("/static/",
		http.FileServer(RelativeFileSystem{&data.Path})))
	log.Println("Serving at http://localhost:5555/ ...")
	log.Fatal(http.ListenAndServe("localhost:5555", nil))
}
