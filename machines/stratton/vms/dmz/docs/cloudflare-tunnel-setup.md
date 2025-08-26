# Cloudflare Tunnel

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com) and login
2. Navigate to Networks -> Tunnels in the side bar
3. Click on "Add a tunnel"
4. Select Cloudflared
5. Name tunnel "Homeserver"
6. Select docker environment and copy the command.
7. Get the token from the command you just copies and past it in the .env file
8. Start the container