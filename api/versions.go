package api

import (
	"context"

	"connectrpc.com/connect"
	"github.com/charmbracelet/log"
	unmangov1alpha1 "github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1"
	"github.com/unstoppablemango/minecraft-manager/api/dev/unmango/v1alpha1/unmangov1alpha1connect"
)

type versionsServer struct{}

func NewVersionsServer() unmangov1alpha1connect.VersionsServiceHandler {
	return &versionsServer{}
}

// List implements unmangov1alpha1connect.VersionsServiceHandler.
func (v *versionsServer) List(
	ctx context.Context,
	req *connect.Request[unmangov1alpha1.ListRequest],
) (*connect.Response[unmangov1alpha1.ListResponse], error) {
	log.Infof("got request")
	res := connect.NewResponse(&unmangov1alpha1.ListResponse{
		Versions: []*unmangov1alpha1.Version{{
			Version: "TEST",
		}},
	})

	return res, nil
}
