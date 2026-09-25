// labctl is a diagnostic client, not a server. It verifies the common service
// on all three independently deployed nodes.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/streaming-live-kalman/filter/pkg/labclient"
)

func main() {
	tx := flag.String("tx", "127.0.0.1:55051", "transmitter endpoint")
	rx := flag.String("rx", "127.0.0.1:55052", "receiver endpoint")
	controller := flag.String("controller", "127.0.0.1:55053", "controller endpoint")
	flag.Parse()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	client, err := labclient.Dial(ctx, labclient.Endpoints{Transmitter: *tx, Receiver: *rx, Controller: *controller})
	if err != nil {
		fail(err)
	}
	defer client.Close()
	infos, err := client.NodeInfo(ctx)
	if err != nil {
		fail(err)
	}
	statuses, err := client.NodeStatuses(ctx)
	if err != nil {
		fail(err)
	}
	result := struct {
		Nodes    any `json:"nodes"`
		Statuses any `json:"statuses"`
	}{infos, statuses}
	b, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		fail(err)
	}
	fmt.Println(string(b))
}

func fail(err error) { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
