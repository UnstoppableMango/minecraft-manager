package api

import (
	"net/http"
	"os"

	"connectrpc.com/grpcreflect"
	"github.com/olivere/vite"
	"github.com/unmango/go/cli"
	"github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1/unmangov1alpha1connect"
	"github.com/unstoppablemango/minecraft-manager/env"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

func NewHandler() http.Handler {
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
		NewVersionsServer(),
	))

	reflector := grpcreflect.NewStaticReflector(
		unmangov1alpha1connect.VersionsServiceName,
	)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	return h2c.NewHandler(mux, &http2.Server{})
}
