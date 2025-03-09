import { serve } from "bun";
import index from "./index.html";
import { CoreV1Api, CustomObjectsApi, KubeConfig } from '@kubernetes/client-node';

const server = serve({
  routes: {
    // Serve index.html for all unmatched routes.
    "/*": index,

    "/api/test": async () => {
      const kc = new KubeConfig();
      kc.loadFromDefault();

      // const k8s = kc.makeApiClient(CustomObjectsApi);
      // const obj = await k8s.listNamespacedCustomObject({
      //   namespace: 'default',
      //   group: 'shulkermc.io',
      //   plural: 'minecraftclusters',
      //   version: 'v1alpha1',
      // });
      const k8s = kc.makeApiClient(CoreV1Api);
      const obj = await k8s.listNamespacedPod({ namespace: 'default' });

      return Response.json({
        message: JSON.stringify(obj),
      });
    },

    "/api/hello": {
      async GET(req) {
        return Response.json({
          message: "Hello, world!",
          method: "GET",
        });
      },
      async PUT(req) {
        return Response.json({
          message: "Hello, world!",
          method: "PUT",
        });
      },
    },

    "/api/hello/:name": async (req) => {
      const name = req.params.name;
      return Response.json({
        message: `Hello, ${name}!`,
      });
    },
  },

  development: process.env.NODE_ENV !== "production",
});

console.log(`🚀 Server running at ${server.url}`);
