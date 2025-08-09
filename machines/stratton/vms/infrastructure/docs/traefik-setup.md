# How to setup Traefik
1. On your host you want to deploy Traefik you need to create a acme.json file in data dir. Run `touch data/acme.json` (same dir as config.yml and traefik.yml)
2. Chmod acme with: `chmod 600 data/acme.json`
3. Setup Cloudflare DNS and get token with DNS edit capabilities. [YT Tutorial (at 19 min)](https://www.youtube.com/watch?v=CmUzMi5QLzI)
4. Put in correct details in .env file  
   ````
   TRAEFIK_DASHBOARD_CREDENTIALS=<username:password thing> # Run .... to get it
   CF_API_EMAIL=<YOUR_CLOUDFLARE_EMAIL>
   CF_DNS_API_TOKEN=<YOUR_CLOUDFLARE_DNS_API_TOKEN>
   ````
5. Start container wite rootfull docker: `sudo docker compose `
6. Now look att `crowdsec-setup.md` and `authentik-setup.md` and set them up completly.
7. You should be good to go