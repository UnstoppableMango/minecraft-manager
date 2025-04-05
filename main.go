package main

import (
	"net/http"
	"os"

	"connectrpc.com/grpcreflect"
	"github.com/charmbracelet/log"
	"github.com/olivere/vite"
	"github.com/unmango/go/cli"
	"github.com/unstoppablemango/minecraft-manager/api"
	"github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1/unmangov1alpha1connect"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

func main() {
	mux := http.NewServeMux()
	v, err := vite.NewHandler(vite.Config{
		FS:      os.DirFS("."),
		IsDev:   true,
		ViteURL: "http://localhost:5173",
	})
	if err != nil {
		cli.Fail(err)
	}

	mux.Handle("/", v)
	mux.Handle(unmangov1alpha1connect.NewVersionsServiceHandler(
		api.NewVersionsServer(),
	))

	reflector := grpcreflect.NewStaticReflector(
		unmangov1alpha1connect.VersionsServiceName,
	)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	addr := ":6969"
	server := h2c.NewHandler(mux, &http2.Server{})

	log.Infof("Listening on http://%s", addr)
	if err := http.ListenAndServe(addr, server); err != nil {
		cli.Fail(err)
	}
}
