package main

import (
	"net/http"
	"os"

	"connectrpc.com/grpcreflect"
	"github.com/charmbracelet/log"
	"github.com/unmango/go/cli"
	"github.com/unstoppablemango/minecraft-manager/api"
	"github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1/unmangov1alpha1connect"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

func main() {
	mux := http.NewServeMux()
	www := os.Getenv("WWW_PATH")
	if www == "" {
		www = "/srv/www"
	}

	if f, err := os.Stat(www); err == nil && f.IsDir() {
		log.Info("Serving files", "path", www)
		mux.Handle("/", http.FileServer(http.Dir(www)))
	}

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

	log.Info("Serving", "addr", addr)
	if err := http.ListenAndServe(addr, server); err != nil {
		cli.Fail(err)
	}
}
