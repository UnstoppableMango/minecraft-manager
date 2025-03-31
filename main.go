package main

import (
	"fmt"
	"net"

	"github.com/unmango/go/cli"
	"github.com/unstoppablemango/minecraft-manager/api"
	unmangov1alpha1 "github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	lis, err := net.Listen("tcp", "localhost:6969")
	if err != nil {
		cli.Fail(err)
	}

	server := grpc.NewServer()
	unmangov1alpha1.RegisterVersionsServiceServer(
		server, api.NewVersionServer(),
	)

	reflection.Register(server)

	fmt.Println("Serving localhost:6969")
	if err := server.Serve(lis); err != nil {
		cli.Fail(err)
	}
}
