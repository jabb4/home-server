# Setup for both Radarr ans Sonarr (same steps)

1. Enable Basic (Browser Popup) authentication and put in username and password.
2. Go to Settings -> Download Clients and add SABnzbd
3. Go to Settings -> Profiles and remove the all


## For Radarr only:
1. Go to Settings -> Media Management and add root folder /data/media/movies/

## For Sonarr only:
1. Go to Settings -> Media Management and add root folder /data/media/tv/

## When you have done the above on both radarr and sonarr
4. Put your Sonarr and Radarr base url and api key into recyclarr config/secrets.yml
4. Run recyclarr container to sync quality profiles (sudo docker compose --rm recyclarr sync)