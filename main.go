package main

import (
	"fmt"
	"net/http"

	"connectrpc.com/grpcreflect"
	"github.com/unmango/go/cli"
	"github.com/unstoppablemango/minecraft-manager/api"
	"github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1/unmangov1alpha1connect"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

func main() {
	path, handler := unmangov1alpha1connect.NewVersionsServiceHandler(
		api.NewVersionsServer(),
	)
	reflector := grpcreflect.NewStaticReflector(
		unmangov1alpha1connect.VersionsServiceName,
	)

	mux := http.NewServeMux()
	mux.Handle(path, handler)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	addr := "localhost:6969"
	server := h2c.NewHandler(mux, &http2.Server{})

	fmt.Println("Serving", addr)
	if err := http.ListenAndServe(addr, server); err != nil {
		cli.Fail(err)
	}
}
