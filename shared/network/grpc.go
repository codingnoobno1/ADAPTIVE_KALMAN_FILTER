package network

import (
	"context"
	"math/rand"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func Dial(ctx context.Context, address string) (*grpc.ClientConn, error) {
	return grpc.NewClient(address, grpc.WithTransportCredentials(insecure.NewCredentials()))
}

func Backoff(attempt int) time.Duration {
	if attempt > 6 {
		attempt = 6
	}
	base := time.Duration(1<<attempt) * 250 * time.Millisecond
	return base + time.Duration(rand.Intn(250))*time.Millisecond
}
