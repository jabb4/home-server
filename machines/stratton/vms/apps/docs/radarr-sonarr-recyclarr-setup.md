# Setup for both Radarr ans Sonarr (same steps)

1. Enable Form authentication and put in username and password.
2. Go to Settings -> Download Clients and add SABnzbd
3. Go to Settings -> Profiles and remove the all


## For Radarr only:
1. Go to Settings -> Media Management and add root folder /data/media/movies/

## For Sonarr only:
1. Go to Settings -> Media Management and add root folder /data/media/tv/

## When you have done the above on both radarr and sonarr
4. Put the Sonarr/Radarr URLs and API keys into the Recyclarr stack's `.env`
   file on `apps-vm` (`cp .env.example .env` then fill in `SONARR_API_KEY` and
   `RADARR_API_KEY`).
5. Start the Recyclarr container (`sudo docker compose up -d`). It runs in cron
   mode and syncs on `@weekly`; for an immediate sync run
   `sudo docker compose exec recyclarr recyclarr sync`.