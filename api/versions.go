package api

import (
	"context"

	unmangov1alpha1 "github.com/UnstoppableMango/minecraft-manager/api/dev/unmango/v1alpha1"
)

type versionsServer struct {
	unmangov1alpha1.UnimplementedVersionsServiceServer
}

func NewVersionServer() unmangov1alpha1.VersionsServiceServer {
	return &versionsServer{}
}

func (s *versionsServer) List(ctx context.Context, req *unmangov1alpha1.ListRequest) (*unmangov1alpha1.ListResponse, error) {
	res := &unmangov1alpha1.ListResponse{
		Versions: []*unmangov1alpha1.Version{{
			Version: "TEST",
		}},
	}

	return res, nil
}
