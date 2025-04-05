package main

import (
	"net"
	"net/http"
	"os"

	"connectrpc.com/grpcreflect"
	"github.com/charmbracelet/log"
	"github.com/olivere/vite"
	"github.com/unmango/go/cli"
	"github.com/unstoppablemango/minecraft-manager/api"
	"github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1/unmangov1alpha1connect"
	"github.com/unstoppablemango/minecraft-manager/env"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

func main() {
	vconf := vite.Config{
		IsDev:   env.IsDev(),
		ViteURL: "http://localhost:5173",
	}
	if env.IsDev() {
		vconf.FS = os.DirFS(".")
	} else {
		vconf.FS = os.DirFS("/srv/www")
	}

	mux := http.NewServeMux()
	if v, err := vite.NewHandler(vconf); err != nil {
		cli.Fail(err)
	} else {
		mux.Handle("/", v)
	}

	mux.Handle(unmangov1alpha1connect.NewVersionsServiceHandler(
		api.NewVersionsServer(),
	))

	reflector := grpcreflect.NewStaticReflector(
		unmangov1alpha1connect.VersionsServiceName,
	)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	lis, err := net.Listen("tcp", ":6969")
	if err != nil {
		cli.Fail(err)
	}

	server := h2c.NewHandler(mux, &http2.Server{})
	log.Infof("Listening on http://%s", lis.Addr())
	if err := http.Serve(lis, server); err != nil {
		cli.Fail(err)
	}
}
