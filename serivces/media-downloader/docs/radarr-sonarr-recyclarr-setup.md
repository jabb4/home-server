# Setup for both Radarr ans Sonarr (same steps)

1. Enable Form authentication and put in username and password.
2. Go to Settings -> Download Clients and add SABnzbd
3. Go to Settings -> Profiles and remove the all


4. Go to Settings -> Media Management and leave "Use Hardlinks instead of Copy"
   off. On Media PI `/data/usenet` is the local SSD and `/data/media` is the
   UNAS NFS mount, so imports are a copy across filesystems either way — see
   [`machines/media-pi/README.md`](../../../machines/media-pi/README.md).

## For Radarr only:
1. Go to Settings -> Media Management and add root folder /data/media/movies/

## For Sonarr only:
1. Go to Settings -> Media Management and add root folder /data/media/tv/

## When you have done the above on both radarr and sonarr
5. Put `SONARR_API_KEY` and `RADARR_API_KEY` into the Recyclarr stack's
   environment variables in the Dockhand UI (Stack -> Environment Variables).
   `serivces/recyclarr/.env.example` documents every key.
6. Deploy the Recyclarr stack from Dockhand. It runs in cron mode and syncs on
   `@weekly`; for an immediate sync run
   `sudo docker exec recyclarr recyclarr sync` on Media PI.