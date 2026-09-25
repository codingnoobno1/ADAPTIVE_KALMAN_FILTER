// Package labclient is a reusable Go SDK for all three Live Kalman services.
package labclient

import (
	"context"
	"fmt"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	txv1 "github.com/streaming-live-kalman/filter/gen/tx/v1"
	"github.com/streaming-live-kalman/filter/shared/network"
	"google.golang.org/grpc"
)

type Endpoints struct{ Transmitter, Receiver, Controller string }

type Client struct {
	TX                             txv1.TransmitterServiceClient
	RX                             rxv1.ReceiverServiceClient
	Controller                     controlv1.ControllerServiceClient
	TXNode, RXNode, ControllerNode commonv1.NodeServiceClient
	connections                    []*grpc.ClientConn
}

func Dial(ctx context.Context, endpoints Endpoints) (*Client, error) {
	addresses := []string{endpoints.Transmitter, endpoints.Receiver, endpoints.Controller}
	conns := make([]*grpc.ClientConn, 0, 3)
	for _, address := range addresses {
		if address == "" {
			closeAll(conns)
			return nil, fmt.Errorf("all three endpoints are required")
		}
		conn, err := network.Dial(ctx, address)
		if err != nil {
			closeAll(conns)
			return nil, fmt.Errorf("dial %s: %w", address, err)
		}
		conns = append(conns, conn)
	}
	return &Client{TX: txv1.NewTransmitterServiceClient(conns[0]), RX: rxv1.NewReceiverServiceClient(conns[1]), Controller: controlv1.NewControllerServiceClient(conns[2]), TXNode: commonv1.NewNodeServiceClient(conns[0]), RXNode: commonv1.NewNodeServiceClient(conns[1]), ControllerNode: commonv1.NewNodeServiceClient(conns[2]), connections: conns}, nil
}

func (c *Client) Close() error {
	var first error
	for _, conn := range c.connections {
		if err := conn.Close(); err != nil && first == nil {
			first = err
		}
	}
	return first
}

func (c *Client) NodeInfo(ctx context.Context) ([]*commonv1.NodeInfo, error) {
	clients := []commonv1.NodeServiceClient{c.TXNode, c.RXNode, c.ControllerNode}
	result := make([]*commonv1.NodeInfo, 0, len(clients))
	for _, node := range clients {
		info, err := node.GetNodeInfo(ctx, &commonv1.Empty{})
		if err != nil {
			return nil, err
		}
		result = append(result, info)
	}
	return result, nil
}

func (c *Client) NodeStatuses(ctx context.Context) ([]*commonv1.NodeStatus, error) {
	clients := []commonv1.NodeServiceClient{c.TXNode, c.RXNode, c.ControllerNode}
	result := make([]*commonv1.NodeStatus, 0, len(clients))
	for _, node := range clients {
		status, err := node.GetNodeStatus(ctx, &commonv1.Empty{})
		if err != nil {
			return nil, err
		}
		result = append(result, status)
	}
	return result, nil
}
func closeAll(conns []*grpc.ClientConn) {
	for _, conn := range conns {
		_ = conn.Close()
	}
}
