# How to setup Traefik
1. On your host you want to deploy Traefik you need to create a acme.json file in data dir. Run `touch /srv/docker/traefik/acme.json` (same dir as config.yml and traefik.yml)
2. Chmod acme with: `chmod 600 /srv/docker/traefik/acme.json`
3. Setup Cloudflare DNS and get token with DNS edit capabilities. [YT Tutorial (at 19 min)](https://www.youtube.com/watch?v=CmUzMi5QLzI)
4. Put in correct details in .env file in portainer 
   ````
   TRAEFIK_DASHBOARD_CREDENTIALS=<username:password thing> # Run .... to get it
   CF_API_EMAIL=<YOUR_CLOUDFLARE_EMAIL>
   CF_DNS_API_TOKEN=<YOUR_CLOUDFLARE_DNS_API_TOKEN>
   CROWDSEC_BOUNCER_API_KEY=<API_KEY>
   ````
5. Start docker container in portainer.
6. In crowdsec container run `crowdsec cscli bouncers add bouncer-traefik`
7. Save the API that it gives you and put it in the .env file `CROWDSEC_BOUNCER_API_KEY=<API_KEY>`
8. Restart container
9. Now look at `authentik-setup.md` and set it up completely.
10. You should be good to go