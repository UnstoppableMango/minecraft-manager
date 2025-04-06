package main

import (
	"context"
	"flag"
	"net"
	"net/http"
	"path/filepath"

	"github.com/charmbracelet/log"
	"github.com/unmango/go/cli"
	"github.com/unstoppablemango/minecraft-manager/api"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

func main() {
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}
	flag.Parse()

	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		cli.Fail(err)
	}

	client, err := kubernetes.NewForConfig(config)
	if err != nil {
		cli.Fail(err)
	}

	podList, err := client.CoreV1().
		Pods("default").
		List(context.Background(), v1.ListOptions{})
	if err != nil {
		cli.Fail(err)
	}

	log.Infof("Iterating pods")
	for _, p := range podList.Items {
		log.Infof("Got pod %s", p.Name)
	}

	lis, err := net.Listen("tcp", ":6969")
	if err != nil {
		cli.Fail(err)
	}

	server := api.NewHandler()
	log.Infof("Listening on http://%s", lis.Addr())
	if err := http.Serve(lis, server); err != nil {
		cli.Fail(err)
	}
}
