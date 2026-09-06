# Setup for both Radarr ans Sonarr (same steps)

1. Enable Form authentication and put in username and password.
2. Go to Settings -> Download Clients and add SABnzbd. Host `localhost`, port `8080` - they share the gluetun network namespace
3. Go to Settings -> Profiles and remove the all
4. Go to Settings -> Media Management (Advnaced settings) and leave "Use Hardlinks instead of Copy"
   off. On Media PI `/data/usenet` is the local SSD and `/data/media` is the
   UNAS NFS mount, so imports are a copy across filesystems either way — see
   [`machines/media-pi/README.md`](../../../machines/media-pi/README.md).
5. Go to Settings -> Profiles and remove all default profiles.

## For Radarr only:
Go to Settings -> Media Management and add root folder /data/media/movies/

## For Sonarr only:
Go to Settings -> Media Management and add root folder /data/media/tv/

## Recyclarr

Recyclarr runs in this same stack and reads the same `SONARR_API_KEY` /
`RADARR_API_KEY` values that pin the keys on Sonarr and Radarr, so there is
nothing to copy out of the UIs — it is already wired once those are set in the
Dockhand environment store.

It runs in cron mode and syncs on `@weekly`. For an immediate sync run
`sudo docker exec recyclarr recyclarr sync` on Media PI.
