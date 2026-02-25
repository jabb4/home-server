# How to setup the environment with portainer
We use portainer to spin up all our containers from github repo

## Deploy stack
1. Click on stacks
2. Add Stack
3. Name the stack to the name of the service
4. Select Git Repository
5. Set "Repository URL" to: `https://github.com/jabb4/home-server.git`
6. Set "Compose path" to the path of your compose file from the root of your repo. Just write the service and the path should come up.
7. Enable GitOpts updates
8. Set the "Fetch interval" to 24h
9. If you have any config files etc. connected to the docker instance (relative path volumes) you will have to enable "Enable relative path volumes" and set it to: `/srv/docker/portainer`
10. If you have any env variables that you need tot ad you add the by clicking "Add an environment variable" and add it. You can also click "Advanced mode" to be able to copy paste from a file.
11. Click on "Deploy the stack"