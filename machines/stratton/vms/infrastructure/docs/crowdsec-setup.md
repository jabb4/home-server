# How to setup Crowdsec with Traefik
- [YT Tutorial](https://technotim.live/posts/crowdsec-traefik/)
1. Spin up the docker compose in rootfull mode `sudo docker compose up -d`
2. Add Traefik bouncer to crowdsec with `sudo docker exec crowdsec cscli bouncers add bouncer-traefik`
3. Save the API that it gives you and put it in the .env file `CROWDSEC_BOUNCER_API_KEY=<API_KEY>`
4. Restart containers with `sudo docker compose down && sudo docker compose up -d`